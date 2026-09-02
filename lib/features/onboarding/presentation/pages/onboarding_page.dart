import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../bloc/onboarding_bloc.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc.fromContext(context),
      child: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is Complete) {
            context.go(Routing.home);
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: switch (state) {
                  Editing(shoppingDay: final day, selectedPreferences: final selected) =>
                    _OnboardingForm(shoppingDay: day, selectedPreferences: selected),
                  Saving() || Complete() => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingForm extends StatelessWidget {
  final ShoppingDay shoppingDay;
  final List<DietaryPreference> selectedPreferences;

  const _OnboardingForm({required this.shoppingDay, required this.selectedPreferences});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OnboardingBloc>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(t.onboarding.welcomeTitle, style: AppTextStyles.bookTitle),
          const SizedBox(height: 8),
          Text(t.onboarding.welcomeSubtitle, style: AppTextStyles.body),
          const SizedBox(height: 32),
          Text(t.onboarding.shoppingDayTitle, style: AppTextStyles.pageHeading),
          const SizedBox(height: 12),
          WeekdaySelector(
            selected: shoppingDay,
            onSelect: (day) => bloc.add(.selectShoppingDay(day)),
          ),
          const SizedBox(height: 32),
          Text(t.onboarding.dietaryTitle, style: AppTextStyles.pageHeading),
          Text(t.onboarding.dietarySubtitle, style: AppTextStyles.caption),
          const SizedBox(height: 12),
          DietaryChipSelector(
            selected: selectedPreferences,
            onToggle: (pref) => bloc.add(.toggleDietaryPreference(pref)),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => bloc.add(const OnboardingEvent.finish()),
              child: Text(t.onboarding.finish),
            ),
          ),
        ],
      ),
    );
  }
}
