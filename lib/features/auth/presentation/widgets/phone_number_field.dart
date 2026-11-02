import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../domain/phone_number.dart';

/// The phone field's text (the national number, digits only) and the
/// country chosen in its menu. Read with [readPhoneField].
class PhoneFieldController extends TextEditingController {
  PhoneFieldController({PhoneCountry country = PhoneCountry.israel})
    : country = ValueNotifier(country);

  /// Israel unless the user picks another one (or pastes a `+…` number).
  final ValueNotifier<PhoneCountry> country;

  @override
  void dispose() {
    country.dispose();
    super.dispose();
  }
}

/// A phone number field: the country's flag and code in a menu on the
/// left, the number itself on the right. The number takes digits only — a
/// dash or a space typed or pasted is dropped on the spot — and a pasted
/// or autofilled `+972…` loses its code and moves the menu to that country.
class PhoneNumberField extends StatelessWidget {
  final PhoneFieldController controller;
  final String? errorText;
  final bool autofill;
  final ValueChanged<String>? onSubmitted;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.errorText,
    this.autofill = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PhoneCountry>(
      valueListenable: controller.country,
      builder: (context, country, _) => Row(
        // The code sits before the number, as it is dialled, in every
        // language.
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.std),
              onTap: () async {
                final picked = await showPhoneCountrySheet(context, country);
                if (picked == null) return;
                controller.country.value = picked;
                // A number longer than the new country allows is cut.
                final digits = phoneFieldDigits(controller.text, picked).digits;
                if (digits != controller.text) controller.text = digits;
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: t.auth.countryCode,
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                  suffixIconConstraints: const BoxConstraints(minWidth: 28),
                ),
                child: _CountryLabel(country: country),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofillHints: autofill
                  ? const [AutofillHints.telephoneNumber]
                  : null,
              inputFormatters: [_PhoneDigitsFormatter(controller)],
              style: AppTextStyles.bodyMd,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: t.auth.phoneNumber,
                hintText: country.example,
                errorText: errorText,
                errorMaxLines: 3,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The code alone on the form; the flags are in the menu's list.
class _CountryLabel extends StatelessWidget {
  final PhoneCountry country;

  const _CountryLabel({required this.country});

  @override
  Widget build(BuildContext context) {
    return Text(
      '+${country.dial}',
      textDirection: TextDirection.ltr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMd,
    );
  }
}

/// The country's name in the app's language.
String phoneCountryName(PhoneCountry country) =>
    switch (t['countries.${country.iso}']) {
      final String name => name,
      _ => country.iso,
    };

/// Whether [country] answers [query]: its name (in the app's language or
/// English), its letters or its code, with or without the `+`.
bool phoneCountryMatches(PhoneCountry country, String query) {
  final q = query.trim().toLowerCase().replaceFirst('+', '');
  if (q.isEmpty) return true;
  return phoneCountryName(country).toLowerCase().contains(q) ||
      country.englishName.toLowerCase().contains(q) ||
      country.iso.toLowerCase() == q ||
      country.dial.startsWith(q);
}

/// The country menu: a search box at the top, the list under it. Resolves
/// with the country tapped, or null when closed.
Future<PhoneCountry?> showPhoneCountrySheet(
  BuildContext context,
  PhoneCountry selected,
) => showModalBottomSheet<PhoneCountry>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _CountrySheet(selected: selected),
);

class _CountrySheet extends StatefulWidget {
  final PhoneCountry selected;

  const _CountrySheet({required this.selected});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = [
      for (final c in PhoneCountry.all)
        if (phoneCountryMatches(c, _query)) c,
    ];
    return Padding(
      // Above the keyboard, which the search box opens.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                0,
                AppSpacing.marginMobile,
                AppSpacing.sm,
              ),
              child: TextField(
                autofocus: true,
                style: AppTextStyles.bodyMd,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: t.auth.countrySearch,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (value) => setState(() => _query = value),
                onSubmitted: (_) {
                  if (matches.length == 1) {
                    Navigator.of(context).pop(matches.single);
                  }
                },
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        t.auth.countryNotFound,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final c = matches[index];
                        final isSelected = c == widget.selected;
                        return ListTile(
                          leading: Text(
                            c.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            phoneCountryName(c),
                            style: AppTextStyles.bodyMd,
                          ),
                          trailing: Text(
                            '+${c.dial}',
                            textDirection: TextDirection.ltr,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w700 : null,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Applies [phoneFieldDigits] to every edit, and moves the menu when an
/// international number names another country.
class _PhoneDigitsFormatter extends TextInputFormatter {
  final PhoneFieldController controller;

  _PhoneDigitsFormatter(this.controller);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final (:digits, :country) = phoneFieldDigits(
      newValue.text,
      controller.country.value,
    );
    if (country != controller.country.value) {
      controller.country.value = country;
    }
    if (digits == newValue.text) return newValue;
    // The caret keeps its place among the digits before it.
    final before = newValue.selection.baseOffset < 0
        ? digits.length
        : phoneFieldDigits(
            newValue.text.substring(0, newValue.selection.baseOffset),
            country,
          ).digits.length.clamp(0, digits.length);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: before),
    );
  }
}
