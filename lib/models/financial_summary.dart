class FinancialSummary {
  final double totalRevenue;
  final double totalHpp; // Harga Pokok Penjualan (COGS)
  final double grossProfit;
  final double operationalCost;
  final double netProfit;
  final double cashInHand;

  // Distribusi Dana (Fund Allocation)
  final double stockRestockBudget;
  final double operationalBudget;
  final double emergencyReserve;
  final double profitDraw;

  const FinancialSummary({
    required this.totalRevenue,
    required this.totalHpp,
    required this.grossProfit,
    required this.operationalCost,
    required this.netProfit,
    required this.cashInHand,
    required this.stockRestockBudget,
    required this.operationalBudget,
    required this.emergencyReserve,
    required this.profitDraw,
  });

  factory FinancialSummary.demo() {
    const rev = 284500000.0;
    const hpp = 168000000.0;
    const gross = rev - hpp;
    const op = 38500000.0;
    const net = gross - op;
    return const FinancialSummary(
      totalRevenue: rev,
      totalHpp: hpp,
      grossProfit: gross,
      operationalCost: op,
      netProfit: net,
      cashInHand: 94200000.0,
      stockRestockBudget: 50000000.0,
      operationalBudget: 25000000.0,
      emergencyReserve: 15000000.0,
      profitDraw: 4200000.0,
    );
  }
}
