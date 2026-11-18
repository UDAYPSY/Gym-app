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

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _selectedCategory = "All";

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
        "Thank you for choosing ${gym.branch.branchName}!";

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
      builder: (context, snapshot) {
        final allTx = snapshot.data ?? gym.transactions;
        final currency = gym.branch.currencySymbol;

        final upiTotal = allTx.where((t) => t.paymentMethod == "upi").fold(0.0, (acc, t) => acc + t.amount);
        final cashTotal = allTx.where((t) => t.paymentMethod == "cash").fold(0.0, (acc, t) => acc + t.amount);
        final totalRevenue = allTx.fold(0.0, (acc, t) => acc + t.amount);
        final totalDues = gym.getTotalPendingDues();

        final filteredTx = allTx.where((t) {
          if (_selectedCategory == "All") return true;
          return t.category.toLowerCase().contains(_selectedCategory.toLowerCase());
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Financial Ledger & Tax Invoices",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Total Lifetime Revenue: $currency${totalRevenue.toStringAsFixed(0)}",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Financial Metric Cards
                Row(
                  children: [
                    Expanded(child: _metricCard("UPI COLLECTIONS", "$currency${upiTotal.toStringAsFixed(0)}", Icons.qr_code, AppColors.primary)),
                    const SizedBox(width: 14),
                    Expanded(child: _metricCard("CASH IN HAND", "$currency${cashTotal.toStringAsFixed(0)}", Icons.money, const Color(0xFF3B82F6))),
                    const SizedBox(width: 14),
                    Expanded(child: _metricCard("PENDING DUES", "$currency${totalDues.toStringAsFixed(0)}", Icons.pending_actions, AppColors.statusDues)),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Chips Filter
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

                // Transaction Table List
                Expanded(
                  child: filteredTx.isEmpty
                      ? const Center(
                          child: Text(
                            "No financial records match this category.",
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
            ),
          ),
        );
      },
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
