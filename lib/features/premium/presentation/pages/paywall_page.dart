import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/legal_links.dart';
import '../../../../core/monetization/entitlement_service.dart';
import '../../../household/domain/household_entity.dart';
import '../../../../core/monetization/monetization_config.dart';
import '../../../../core/monetization/purchases_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/paywall_offer.dart';
import '../../../../core/widgets/app_dialog.dart';

/// The one place EasyPlate sells anything: the premium subscription that
/// switches off ads and the daily quotas.
///
/// Reached from the account menu. Everything on it is required somewhere:
/// the price and billing period on the button (App Store 3.1.2), a restore
/// button (App Store 3.1.1), the auto-renewal disclosure and the two legal
/// links (both stores). Keep those when redesigning.
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> with WidgetsBindingObserver {
  final _entitlement = EntitlementService();
  Map<String, Package> _packages = const {};
  HouseholdTier? _tier;
  List<PaywallOffer> _offers = const [];
  String? _selectedId;
  bool _loading = true;
  bool _busy = false;

  /// Set when the store's redeem screen was opened: the purchase it makes
  /// happens outside the app, so the receipts are re-read on the way back.
  bool _awaitingRedeem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entitlement.addListener(_onEntitlement);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entitlement.removeListener(_onEntitlement);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingRedeem) {
      _awaitingRedeem = false;
      _restore();
    }
  }

  Future<void> _redeem() async {
    String? code;
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      code = await AppDialog.prompt(
        context,
        title: t.premium.redeemTitle,
        hint: t.premium.redeemHint,
        icon: Icons.confirmation_number_rounded,
        confirmLabel: t.premium.redeemConfirm,
      );
      if (code == null || !mounted) return;
    }
    _awaitingRedeem = true;
    final opened = await PurchasesService().redeemCode(code: code);
    if (!opened) {
      _awaitingRedeem = false;
      if (mounted) _hint(t.premium.unavailable);
    }
  }

  void _onEntitlement() => setState(() {});

  Future<void> _load() async {
    final offering = await PurchasesService().currentOffering();
    if (!mounted) return;
    final packages = offering?.availablePackages ?? const <Package>[];
    var offers = packages.map(PaywallOffer.fromPackage).toList();
    // An opening price is shown only to an account that can still take it.
    if (offers.any((o) => o.intro != null)) {
      final ineligible = await PurchasesService().introIneligible(
        offers.where((o) => o.intro != null).map((o) => o.productId),
      );
      offers = [
        for (final o in offers)
          ineligible.contains(o.productId) ? o.withoutIntro() : o,
      ];
    }
    if (!mounted) return;
    setState(() {
      _packages = {for (final p in packages) p.identifier: p};
      _offers = offers;
      _tier = null;
      _selectedId = PaywallOffer.defaultSelection(_visible(_offers, null));
      _loading = false;
    });
  }

  static List<PaywallOffer> _visible(
    List<PaywallOffer> offers,
    HouseholdTier? tier,
  ) => [
    for (final offer in offers)
      if (offer.tier == tier) offer,
  ];

  void _selectTier(HouseholdTier? tier) => setState(() {
    _tier = tier;
    _selectedId = PaywallOffer.defaultSelection(_visible(_offers, tier));
  });

  Future<void> _purchase() async {
    final package = _packages[_selectedId];
    if (package == null) return;
    setState(() => _busy = true);
    try {
      final premium = await PurchasesService().purchase(package);
      if (!mounted) return;
      if (premium) _notify(t.premium.purchased);
    } catch (e) {
      debugPrint('Purchase failed: $e');
      if (mounted) _fail(t.premium.purchaseFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manage() async {
    final opened = await AppDialog.busy(
      context,
      PurchasesService().openSubscriptionManagement,
    );
    if (!opened && mounted) _hint(t.premium.unavailable);
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final premium = await PurchasesService().restore();
      if (!mounted) return;
      premium ? _notify(t.premium.restored) : _hint(t.premium.nothingToRestore);
    } catch (e) {
      debugPrint('Restore failed: $e');
      if (mounted) _fail(t.premium.purchaseFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notify(String message) =>
      AppDialog.success(message: message).notify(context);
  void _hint(String message) =>
      AppDialog.info(message: message).notify(context);
  void _fail(String message) => AppDialog.error(message: message).show(context);

  @override
  Widget build(BuildContext context) {
    return PaywallView(
      offers: _visible(_offers, _tier),
      tiers: PaywallOffer.tiersIn(_offers),
      tier: _tier,
      onSelectTier: _selectTier,
      selectedId: _selectedId,
      aiPerDay: MonetizationConfig.limits.premiumAiExtractions,
      isPremium: _entitlement.isPremium,
      loading: _loading,
      busy: _busy,
      onSelect: (id) => setState(() => _selectedId = id),
      onPurchase: _purchase,
      onRestore: _restore,
      onManage: _manage,
      onRedeem: _redeem,
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The screen itself, with no store access: everything it shows comes in as
/// arguments, so it can be rendered with sample offers — the store review
/// screenshot is made that way (test/store_assets).
class PaywallView extends StatelessWidget {
  final List<PaywallOffer> offers;
  final String? selectedId;

  /// The tiers on sale (null = Pro) and the one being looked at. One
  /// entry hides the picker.
  final List<HouseholdTier?> tiers;
  final HouseholdTier? tier;
  final ValueChanged<HouseholdTier?>? onSelectTier;

  /// The premium AI allowance quoted in the benefits list — a Remote Config
  /// value, passed in so the screen stays renderable without Firebase.
  final int aiPerDay;
  final bool isPremium;
  final bool loading;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  /// "Cancel subscription" on the active card: opens the store's management
  /// page, where cancelling only stops the renewal.
  final VoidCallback onManage;

  /// "I have a coupon code": the store's own redemption screen. Null hides
  /// the link.
  final VoidCallback? onRedeem;
  final VoidCallback onBack;

  const PaywallView({
    super.key,
    required this.offers,
    required this.selectedId,
    this.tiers = const [null],
    this.tier,
    this.onSelectTier,
    required this.aiPerDay,
    required this.isPremium,
    required this.loading,
    required this.busy,
    required this.onSelect,
    required this.onPurchase,
    required this.onRestore,
    required this.onManage,
    this.onRedeem,
    required this.onBack,
  });

  PaywallOffer? get _selected {
    for (final offer in offers) {
      if (offer.id == selectedId) return offer;
    }
    return null;
  }

  String _tierLabel(HouseholdTier? tier) => switch (tier) {
    null => t.premium.tierPro,
    HouseholdTier.duo => t.premium.tierDuo,
    HouseholdTier.family => t.premium.tierFamily,
  };

  String _tierHint(HouseholdTier? tier) => switch (tier) {
    null => t.premium.tierProHint,
    HouseholdTier.duo => t.premium.tierDuoHint,
    HouseholdTier.family => t.premium.tierFamilyHint,
  };

  String _periodLabel(PaywallPeriod period) => switch (period) {
    PaywallPeriod.weekly => t.premium.periodWeekly,
    PaywallPeriod.monthly => t.premium.periodMonthly,
    PaywallPeriod.twoMonth => t.premium.periodTwoMonth,
    PaywallPeriod.threeMonth => t.premium.periodThreeMonth,
    PaywallPeriod.sixMonth => t.premium.periodSixMonth,
    PaywallPeriod.annual => t.premium.periodAnnual,
    PaywallPeriod.lifetime => t.premium.periodLifetime,
    PaywallPeriod.other => '',
  };

  /// "per month", for the sentence that says what the price becomes.
  String _perLabel(PaywallPeriod period) => switch (period) {
    PaywallPeriod.weekly => t.premium.perWeekly,
    PaywallPeriod.monthly => t.premium.perMonthly,
    PaywallPeriod.twoMonth => t.premium.perTwoMonth,
    PaywallPeriod.threeMonth => t.premium.perThreeMonth,
    PaywallPeriod.sixMonth => t.premium.perSixMonth,
    PaywallPeriod.annual => t.premium.perAnnual,
    PaywallPeriod.lifetime || PaywallPeriod.other => '',
  };

  /// The card's short line: the opening price and how long it holds. The
  /// full terms sit under the button.
  String _introShort(PaywallIntro intro) => intro.isFree
      ? '${t.premium.free} ${_introSpan(intro)}'
      : '${intro.priceString} ${_introSpan(intro)}';

  String _introSpan(PaywallIntro intro) => switch (intro.unit) {
    PaywallIntroUnit.day => t.premium.introDays(n: intro.count),
    PaywallIntroUnit.week => t.premium.introWeeks(n: intro.count),
    PaywallIntroUnit.month => t.premium.introMonths(n: intro.count),
    PaywallIntroUnit.year => t.premium.introYears(n: intro.count),
  };

  /// The whole deal in one sentence — what is paid now, for how long, and
  /// what the store charges after. Both stores require it next to the
  /// button (App Store 3.1.2, Play subscriptions policy).
  String _introTerms(PaywallOffer offer) {
    final intro = offer.intro!;
    final then = '${offer.priceString} ${_perLabel(offer.period)}'.trim();
    return intro.isFree
        ? t.premium.introFreeTerms(span: _introSpan(intro), then: then)
        : t.premium.introPaidTerms(
            price: intro.priceString,
            span: _introSpan(intro),
            then: then,
          );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.premium.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: onBack,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            const SizedBox(height: AppSpacing.base),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              t.premium.headline,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              t.premium.subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                children: [
                  _Benefit(
                    icon: Icons.block_rounded,
                    label: t.premium.benefitNoAds,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Benefit(
                    icon: Icons.menu_book_rounded,
                    label: t.premium.benefitShared,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Benefit(
                    icon: Icons.auto_awesome_rounded,
                    label: t.premium.benefitAi(count: aiPerDay),
                  ),
                  if (tier case final tier?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _Benefit(
                      icon: Icons.family_restroom_rounded,
                      label: t.premium.benefitHousehold(n: tier.seats),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!isPremium && !loading && tiers.length > 1) ...[
              ClaySegmentedControl(
                segments: [
                  for (final option in tiers)
                    ClaySegment(
                      label: _tierLabel(option),
                      icon: switch (option) {
                        null => Icons.person_rounded,
                        HouseholdTier.duo => Icons.people_rounded,
                        HouseholdTier.family => Icons.family_restroom_rounded,
                      },
                    ),
                ],
                selectedIndex: tiers.indexOf(tier).clamp(0, tiers.length - 1),
                onSelected: (index) => onSelectTier?.call(tiers[index]),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _tierHint(tier),
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (isPremium)
              _ActiveCard(onCancel: busy ? null : onManage)
            else if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (offers.isEmpty)
              Text(
                t.premium.unavailable,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              )
            else ...[
              for (final offer in offers) ...[
                _OfferCard(
                  offer: offer,
                  periodLabel: _periodLabel(offer.period),
                  selected: offer.id == selectedId,
                  highlighted:
                      offer.id == PaywallOffer.defaultSelection(offers) &&
                      offers.length > 1,
                  introTerms: offer.intro == null
                      ? null
                      : _introShort(offer.intro!),
                  onTap: busy ? null : () => onSelect(offer.id),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.base),
              ClayButton(
                label: selected == null
                    ? ''
                    : selected.isLifetime
                    ? t.premium.buyFor(price: selected.priceString)
                    : selected.intro == null
                    ? t.premium.subscribeFor(price: selected.priceString)
                    : selected.intro!.isFree
                    ? t.premium.startFree
                    : t.premium.startFor(price: selected.intro!.priceString),
                icon: Icons.lock_open_rounded,
                expanded: true,
                onPressed: busy || selected == null ? null : onPurchase,
              ),
              if (selected?.intro != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _introTerms(selected!),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                t.premium.legal,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.gutter),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.gutter,
              runSpacing: AppSpacing.xs,
              children: [
                if (!isPremium)
                  _LinkText(
                    label: t.premium.restore,
                    onTap: busy ? null : onRestore,
                  ),
                if (!isPremium && onRedeem != null)
                  _LinkText(
                    label: t.premium.redeem,
                    onTap: busy ? null : onRedeem,
                  ),
                _LinkText(
                  label: t.premium.terms,
                  onTap: () => _open(LegalLinks.terms),
                ),
                _LinkText(
                  label: t.premium.privacy,
                  onTap: () => _open(LegalLinks.privacy),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Benefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.secondaryFixed,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.onSecondaryFixedVariant),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final PaywallOffer offer;
  final String periodLabel;
  final bool selected;
  final bool highlighted;

  /// The opening deal spelled out, when the account can take one.
  final String? introTerms;
  final VoidCallback? onTap;

  const _OfferCard({
    required this.offer,
    required this.periodLabel,
    required this.selected,
    required this.highlighted,
    required this.onTap,
    this.introTerms,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      isActive: selected,
      color: selected ? AppColors.primaryFixed : null,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? AppColors.primary : AppColors.outline,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(periodLabel, style: AppTextStyles.bodyLg),
                if (highlighted)
                  Text(
                    t.premium.bestValue,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                if (introTerms case final terms?)
                  Text(
                    terms,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (offer.intro case final intro?)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  intro.isFree ? t.premium.free : intro.priceString,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  offer.priceString,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            )
          else
            Text(
              offer.priceString,
              style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final VoidCallback? onCancel;

  const _ActiveCard({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      color: AppColors.secondaryFixed,
      child: Column(
        children: [
          Icon(
            Icons.verified_rounded,
            size: 40,
            color: AppColors.onSecondaryFixedVariant,
          ),
          const SizedBox(height: AppSpacing.base),
          // The card is a *fixed* mint in both themes, so its ink is the
          // fixed ink too — the default onSurface goes light in dark mode.
          Text(
            t.premium.activeTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.onSecondaryFixed,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.premium.activeBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSecondaryFixedVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClayButton(
            label: t.premium.cancel,
            icon: Icons.cancel_outlined,
            expanded: true,
            onPressed: onCancel,
          ),
          const SizedBox(height: AppSpacing.base),
          // Says up front what cancelling does: renewal off, paid time kept,
          // nothing refunded — so nobody presses it expecting money back.
          Text(
            t.premium.cancelNote,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSecondaryFixedVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _LinkText({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: onTap == null ? AppColors.outline : AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
