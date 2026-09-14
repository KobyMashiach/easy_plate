import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/legal_links.dart';
import '../../../../core/monetization/entitlement_service.dart';
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

class _PaywallPageState extends State<PaywallPage> {
  final _entitlement = EntitlementService();
  Map<String, Package> _packages = const {};
  List<PaywallOffer> _offers = const [];
  String? _selectedId;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _entitlement.addListener(_onEntitlement);
    _load();
  }

  @override
  void dispose() {
    _entitlement.removeListener(_onEntitlement);
    super.dispose();
  }

  void _onEntitlement() => setState(() {});

  Future<void> _load() async {
    final offering = await PurchasesService().currentOffering();
    if (!mounted) return;
    final packages = offering?.availablePackages ?? const <Package>[];
    setState(() {
      _packages = {for (final p in packages) p.identifier: p};
      _offers = packages.map(PaywallOffer.fromPackage).toList();
      _selectedId = PaywallOffer.defaultSelection(_offers);
      _loading = false;
    });
  }

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

  void _notify(String message) => AppDialog.success(message: message).notify(context);
  void _hint(String message) => AppDialog.info(message: message).notify(context);
  void _fail(String message) => AppDialog.error(message: message).show(context);

  @override
  Widget build(BuildContext context) {
    return PaywallView(
      offers: _offers,
      selectedId: _selectedId,
      isPremium: _entitlement.isPremium,
      loading: _loading,
      busy: _busy,
      onSelect: (id) => setState(() => _selectedId = id),
      onPurchase: _purchase,
      onRestore: _restore,
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
  final bool isPremium;
  final bool loading;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onBack;

  const PaywallView({
    super.key,
    required this.offers,
    required this.selectedId,
    required this.isPremium,
    required this.loading,
    required this.busy,
    required this.onSelect,
    required this.onPurchase,
    required this.onRestore,
    required this.onBack,
  });

  PaywallOffer? get _selected {
    for (final offer in offers) {
      if (offer.id == selectedId) return offer;
    }
    return null;
  }

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
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(t.premium.headline, textAlign: TextAlign.center, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.base),
            Text(
              t.premium.subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                children: [
                  _Benefit(icon: Icons.block_rounded, label: t.premium.benefitNoAds),
                  const SizedBox(height: AppSpacing.sm),
                  _Benefit(icon: Icons.menu_book_rounded, label: t.premium.benefitShared),
                  const SizedBox(height: AppSpacing.sm),
                  _Benefit(icon: Icons.auto_awesome_rounded, label: t.premium.benefitAi),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (isPremium)
              _ActiveCard()
            else if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (offers.isEmpty)
              Text(
                t.premium.unavailable,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              )
            else ...[
              for (final offer in offers) ...[
                _OfferCard(
                  offer: offer,
                  periodLabel: _periodLabel(offer.period),
                  selected: offer.id == selectedId,
                  highlighted: offer.id == PaywallOffer.defaultSelection(offers) && offers.length > 1,
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
                        : t.premium.subscribeFor(price: selected.priceString),
                icon: Icons.lock_open_rounded,
                expanded: true,
                onPressed: busy || selected == null ? null : onPurchase,
              ),
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
                if (!isPremium) _LinkText(label: t.premium.restore, onTap: busy ? null : onRestore),
                _LinkText(label: t.premium.terms, onTap: () => _open(LegalLinks.terms)),
                _LinkText(label: t.premium.privacy, onTap: () => _open(LegalLinks.privacy)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
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
          decoration: const BoxDecoration(color: AppColors.secondaryFixed, shape: BoxShape.circle),
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
  final VoidCallback? onTap;

  const _OfferCard({
    required this.offer,
    required this.periodLabel,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
      onTap: onTap,
      isActive: selected,
      color: selected ? AppColors.primaryFixed : null,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
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
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.secondary),
                  ),
              ],
            ),
          ),
          Text(offer.priceString, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      color: AppColors.secondaryFixed,
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, size: 40, color: AppColors.onSecondaryFixedVariant),
          const SizedBox(height: AppSpacing.base),
          Text(t.premium.activeTitle, textAlign: TextAlign.center, style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.premium.activeBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSecondaryFixedVariant),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
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
