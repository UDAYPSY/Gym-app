import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gym_service.dart';
import '../models/gym_models.dart';
import '../constants/app_constants.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareReceiptWhatsApp(BuildContext context, FinancialTransaction tx) async {
    final gym = GymService();
    final member = gym.getMemberById(tx.memberId);
    final phone = member != null ? member.normalizedPhone : "";

    final receipt = "🧾 *${gym.branch.branchName} — PAYMENT RECEIPT*\n\n"
        "📄 *Invoice #:* ${tx.invoiceNumber}\n"
        "👤 *Member:* ${tx.memberName}\n"
        "📅 *Date:* ${tx.date.toString().split(' ')[0]}\n"
        "💳 *Method:* ${tx.paymentMethod.toUpperCase()}\n"
        "🏷️ *Category:* ${tx.category.toUpperCase()}\n"
        "💰 *Amount Paid:* ${gym.branch.currencySymbol}${tx.amount.toStringAsFixed(0)}\n"
        "🏛️ *CGST (9%):* ${gym.branch.currencySymbol}${tx.cgst.toStringAsFixed(0)}\n"
        "🏛️ *SGST (9%):* ${gym.branch.currencySymbol}${tx.sgst.toStringAsFixed(0)}\n"
        "📝 *Note:* ${tx.notes ?? 'Fee settlement'}\n\n"
        "Thank you for training with ${gym.branch.branchName}!";

    final encoded = Uri.encodeComponent(receipt);
    final url = Uri.parse("https://wa.me/91$phone?text=$encoded");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = GymService();

    return StreamBuilder<List<FinancialTransaction>>(
      stream: gym.transactionsStream,
      builder: (context, txSnapshot) {
        final allTx = txSnapshot.data ?? gym.transactions;
        final currency = gym.branch.currencySymbol;

        final upiTotal = allTx.where((t) => t.paymentMethod == "upi").fold(0.0, (acc, t) => acc + t.amount);
        final cashTotal = allTx.where((t) => t.paymentMethod == "cash").fold(0.0, (acc, t) => acc + t.amount);
        final totalRevenue = allTx.fold(0.0, (acc, t) => acc + t.amount);
        final totalDues = gym.getTotalPendingDues();

        return StreamBuilder<List<GymExpense>>(
          stream: gym.expensesStream,
          builder: (context, expSnapshot) {
            final allExpenses = expSnapshot.data ?? gym.expenses;
            final totalExpenses = allExpenses.fold(0.0, (acc, e) => acc + e.amount);
            final netProfit = totalRevenue - totalExpenses;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Financial Accounting & Expense Ledger",
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Net Operating Profit: $currency${netProfit.toStringAsFixed(0)} (Revenue: $currency${totalRevenue.toStringAsFixed(0)} - Expenses: $currency${totalExpenses.toStringAsFixed(0)})",
                              style: TextStyle(
                                color: netProfit >= 0 ? AppColors.primaryLight : AppColors.statusExpired,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: AppColors.primary,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          tabs: const [
                            Tab(icon: Icon(Icons.receipt_long, size: 18), text: "Revenue & Invoices"),
                            Tab(icon: Icon(Icons.outbox, size: 18), text: "Running Expenses"),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Revenue & Invoices
                          _buildRevenueTab(context, allTx, currency, upiTotal, cashTotal, totalDues),

                          // Tab 2: Expenses & Operating Margin
                          _buildExpensesTab(context, allExpenses, currency, totalRevenue, totalExpenses, netProfit),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRevenueTab(
    BuildContext context,
    List<FinancialTransaction> allTx,
    String currency,
    double upiTotal,
    double cashTotal,
    double totalDues,
  ) {
    final filteredTx = allTx.where((t) {
      if (_selectedCategory == "All") return true;
      return t.category.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _metricCard("UPI COLLECTIONS", "$currency${upiTotal.toStringAsFixed(0)}", Icons.qr_code, AppColors.primary)),
            const SizedBox(width: 14),
            Expanded(child: _metricCard("CASH IN HAND", "$currency${cashTotal.toStringAsFixed(0)}", Icons.money, const Color(0xFF3B82F6))),
            const SizedBox(width: 14),
            Expanded(child: _metricCard("PENDING DUES", "$currency${totalDues.toStringAsFixed(0)}", Icons.pending_actions, AppColors.statusDues)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _categoryChip("All"),
            const SizedBox(width: 8),
            _categoryChip("Membership"),
            const SizedBox(width: 8),
            _categoryChip("Locker"),
            const SizedBox(width: 8),
            _categoryChip("Dues"),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredTx.isEmpty
              ? const Center(
                  child: Text(
                    "No payment records found.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredTx.length,
                  itemBuilder: (context, index) {
                    final tx = filteredTx[index];
                    final isUpi = tx.paymentMethod == "upi";

                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUpi ? const Color(0xFF064E3B) : const Color(0xFF1E3A8A),
                          child: Icon(
                            isUpi ? Icons.account_balance : Icons.attach_money,
                            color: isUpi ? AppColors.primary : const Color(0xFF60A5FA),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          "${tx.memberName} — $currency${tx.amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Inv #${tx.invoiceNumber} • ${tx.paymentMethod.toUpperCase()} • ${tx.notes ?? tx.category}",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.share, color: Color(0xFF25D366)),
                          tooltip: "Send Receipt via WhatsApp",
                          onPressed: () => _shareReceiptWhatsApp(context, tx),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab(
    BuildContext context,
    List<GymExpense> allExpenses,
    String currency,
    double totalRevenue,
    double totalExpenses,
    double netProfit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _metricCard("TOTAL REVENUE", "$currency${totalRevenue.toStringAsFixed(0)}", Icons.trending_up, AppColors.primary)),
            const SizedBox(width: 14),
            Expanded(child: _metricCard("RUNNING EXPENSES", "$currency${totalExpenses.toStringAsFixed(0)}", Icons.trending_down, AppColors.statusExpired)),
            const SizedBox(width: 14),
            Expanded(
              child: _metricCard(
                "NET OPERATING PROFIT",
                "$currency${netProfit.toStringAsFixed(0)}",
                netProfit >= 0 ? Icons.account_balance_wallet : Icons.warning,
                netProfit >= 0 ? AppColors.primaryLight : AppColors.statusExpired,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Operational Expense Log",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddExpenseModal(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Log Expense"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                foregroundColor: AppColors.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: allExpenses.isEmpty
              ? const Center(
                  child: Text(
                    "No operational expenses recorded.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: allExpenses.length,
                  itemBuilder: (context, index) {
                    final exp = allExpenses[index];

                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF7F1D1D),
                          child: Icon(Icons.outbox, color: AppColors.statusExpired, size: 18),
                        ),
                        title: Text(
                          "${exp.title} — $currency${exp.amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "🏷️ ${exp.category} • 💳 ${exp.paymentMode} • 📅 ${exp.date.toString().split(' ')[0]}\n📝 ${exp.note}",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                          onPressed: () async {
                            await GymService().deleteExpense(exp.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Deleted ${exp.title}")),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddExpenseModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String category = "Equipment AMC & Repair";
    String paymentMode = "UPI";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setExpState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text("Log Gym Operating Expense", style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Expense Title *")),
                const SizedBox(height: 10),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹) *")),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: const [
                    DropdownMenuItem(value: "Equipment AMC & Repair", child: Text("Equipment AMC & Repair")),
                    DropdownMenuItem(value: "Electricity/HVAC", child: Text("Electricity / HVAC")),
                    DropdownMenuItem(value: "Premises Rent", child: Text("Premises Rent")),
                    DropdownMenuItem(value: "Trainer Salaries", child: Text("Trainer Salaries & Commissions")),
                    DropdownMenuItem(value: "Cleaning/Sanitization", child: Text("Cleaning & Housekeeping")),
                    DropdownMenuItem(value: "Supplements Restock", child: Text("Supplements & Retail Restock")),
                  ],
                  onChanged: (val) {
                    if (val != null) setExpState(() => category = val);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: paymentMode,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: const InputDecoration(labelText: "Payment Mode"),
                  items: const [
                    DropdownMenuItem(value: "UPI", child: Text("UPI")),
                    DropdownMenuItem(value: "Cash", child: Text("Cash")),
                    DropdownMenuItem(value: "Bank Transfer", child: Text("Bank Transfer")),
                    DropdownMenuItem(value: "Card", child: Text("Card")),
                  ],
                  onChanged: (val) {
                    if (val != null) setExpState(() => paymentMode = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Notes / Vendor info")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (titleCtrl.text.trim().isNotEmpty && amt > 0) {
                  await GymService().addExpense(GymExpense(
                    id: "exp_${DateTime.now().millisecondsSinceEpoch}",
                    title: titleCtrl.text.trim(),
                    category: category,
                    amount: amt,
                    date: DateTime.now(),
                    paymentMode: paymentMode,
                    note: noteCtrl.text.trim(),
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Recorded expense of ₹$amt for ${titleCtrl.text.trim()}")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Save Expense"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = label),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : Colors.white12),
    );
  }
}
