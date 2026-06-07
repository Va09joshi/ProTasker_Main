import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/role_guard.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/provider_earnings_providers.dart';

class ProviderEarningsScreen extends ConsumerWidget {
  const ProviderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGuard.provider(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Earnings'),
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.paddingMD),
              child: AppButton(
                label: 'Withdraw',
                variant: ButtonVariant.ghost,
                fullWidth: false,
                onPressed: () => _showWithdrawSheet(context),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(providerEarningsDataProvider);
              ref.invalidate(earningsHistoryProvider);
              await ref.read(providerEarningsDataProvider.future);
            },
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSegmentedControl(ref),
                        const SizedBox(height: AppDimensions.paddingLG),
                        _buildSummarySection(ref),
                        const SizedBox(height: AppDimensions.paddingXL),
                        const Text('Analytics', style: AppTextStyles.headingLarge),
                        const SizedBox(height: AppDimensions.paddingMD),
                        _buildChartSection(ref),
                        const SizedBox(height: AppDimensions.paddingXL),
                        const Text('Recent Transactions', style: AppTextStyles.headingLarge),
                        const SizedBox(height: AppDimensions.paddingMD),
                      ],
                    ),
                  ),
                ),
                _buildHistoryList(ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(WidgetRef ref) {
    final period = ref.watch(earningsPeriodProvider);
    return SegmentedButton<EarningsPeriod>(
      segments: const [
        ButtonSegment(value: EarningsPeriod.thisWeek, label: Text('This Week')),
        ButtonSegment(value: EarningsPeriod.thisMonth, label: Text('This Month')),
        ButtonSegment(value: EarningsPeriod.allTime, label: Text('All Time')),
      ],
      selected: {period},
      onSelectionChanged: (Set<EarningsPeriod> newSelection) {
        ref.read(earningsPeriodProvider.notifier).updatePeriod(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return AppColors.surfaceAlt;
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return AppColors.textPrimary;
          return AppColors.textSecondary;
        }),
        side: WidgetStateProperty.all(BorderSide(color: AppColors.border, width: AppDimensions.cardBorderWidth)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLG))),
      ),
    );
  }

  Widget _buildSummarySection(WidgetRef ref) {
    final dataAsync = ref.watch(providerEarningsDataProvider);

    return dataAsync.when(
      data: (data) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimensions.paddingMD,
          crossAxisSpacing: AppDimensions.paddingMD,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard('Net Earnings', '₹${data.summary.netEarnings.toStringAsFixed(2)}', AppColors.accent, isHighlighted: true),
            _buildSummaryCard('Gross Earnings', '₹${data.summary.grossEarnings.toStringAsFixed(2)}', AppColors.textPrimary),
            _buildSummaryCard('Platform Fee', '₹${data.summary.platformFee.toStringAsFixed(2)}', AppColors.error),
            _buildSummaryCard('Jobs Completed', '${data.summary.jobsCompleted}', AppColors.success),
          ],
        );
      },
      loading: () => Shimmer.fromColors(
        baseColor: AppColors.surfaceAlt,
        highlightColor: AppColors.background,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimensions.paddingMD,
          crossAxisSpacing: AppDimensions.paddingMD,
          childAspectRatio: 1.5,
          children: List.generate(4, (_) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          )),
        ),
      ),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(providerEarningsDataProvider)),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.accent.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: isHighlighted ? AppColors.accent : AppColors.border,
          width: AppDimensions.cardBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.displayMedium.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildChartSection(WidgetRef ref) {
    final dataAsync = ref.watch(providerEarningsDataProvider);

    return dataAsync.when(
      data: (data) {
        if (data.chartData.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No data')));
        
        double maxY = 0;
        for (var d in data.chartData) {
          if (d.value > maxY) maxY = d.value;
        }
        if (maxY == 0) maxY = 100; // default scale
        
        return Container(
          height: 250,
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final int index = value.toInt();
                      if (index < 0 || index >= data.chartData.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(data.chartData[index].label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text('₹${value.toInt()}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary));
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.chartData.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: AppColors.accent,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
      ),
      error: (e, _) => SizedBox(height: 250, child: ErrorView(message: e.toString(), onRetry: () => ref.refresh(providerEarningsDataProvider))),
    );
  }

  Widget _buildHistoryList(WidgetRef ref) {
    final asyncData = ref.watch(earningsHistoryProvider);

    return asyncData.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              child: const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No transactions yet',
                subtitle: 'Your completed jobs will appear here.',
              ),
            ),
          );
        }
        
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= bookings.length) {
                ref.read(earningsHistoryProvider.notifier).loadMore();
                return const Padding(padding: EdgeInsets.all(AppDimensions.paddingMD), child: Center(child: CircularProgressIndicator()));
              }
              final b = bookings[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM, left: AppDimensions.paddingLG, right: AppDimensions.paddingLG),
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingSM),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: AppDimensions.paddingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.serviceTitle, style: AppTextStyles.labelLarge),
                          const SizedBox(height: 2),
                          Text('${b.clientName} • ${DateFormat.yMMMd().format(b.updatedAt)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('+₹${b.netPrice.toStringAsFixed(2)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.success)),
                        const SizedBox(height: 2),
                        Text('₹${b.grossPrice.toStringAsFixed(2)} gross', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              );
            },
            childCount: bookings.length + (asyncData.isLoading ? 1 : 0),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: LoadingShimmer(type: ShimmerType.list)),
      error: (e, _) => SliverToBoxAdapter(child: ErrorView(message: e.toString(), onRetry: () => ref.refresh(earningsHistoryProvider))),
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: AppDimensions.paddingMD),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_rounded, size: 48, color: AppColors.accent),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            const Text('Withdraw Funds', style: AppTextStyles.headingLarge),
            const SizedBox(height: AppDimensions.paddingMD),
            Text(
              'Bank transfer integration is coming soon! You will be able to transfer your net earnings directly to your registered bank account.', 
              textAlign: TextAlign.center, 
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
            AppButton(
              label: 'Got it',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
