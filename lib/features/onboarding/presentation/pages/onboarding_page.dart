import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
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
            // Lets the auth gate stop redirecting back here before we navigate.
            AuthSessionService().markOnboardingComplete();
            context.go(Routing.home);
          }
        },
        builder: (context, state) {
          return ClayScaffold(
            body: SafeArea(
              child: switch (state) {
                Editing(shoppingDay: final day, selectedPreferences: final selected) =>
                  _OnboardingForm(shoppingDay: day, selectedPreferences: selected),
                Saving() || Complete() => const Center(child: CircularProgressIndicator()),
              },
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          t.onboarding.welcomeTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLgMobile,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          t.onboarding.welcomeSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xl),
        ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClaySectionHeader(title: t.onboarding.shoppingDayTitle),
              const SizedBox(height: AppSpacing.gutter),
              WeekdaySelector(
                selected: shoppingDay,
                onSelect: (day) => bloc.add(.selectShoppingDay(day)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClaySectionHeader(title: t.onboarding.dietaryTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                t.onboarding.dietarySubtitle,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: AppSpacing.gutter),
              DietaryChipSelector(
                selected: selectedPreferences,
                onToggle: (pref) => bloc.add(.toggleDietaryPreference(pref)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ClayButton(
          label: t.onboarding.finish,
          icon: Icons.arrow_back_rounded,
          expanded: true,
          onPressed: () => bloc.add(const OnboardingEvent.finish()),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
