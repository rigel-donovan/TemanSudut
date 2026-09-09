import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class BranchSelectorSheet extends StatelessWidget {
  final bool isDismissible;

  const BranchSelectorSheet({
    super.key,
    this.isDismissible = true,
  });

  static Future<void> show(BuildContext context, {bool isDismissible = true}) {
    return showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BranchSelectorSheet(isDismissible: isDismissible),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final branches = auth.branches;
        final activeBranch = auth.activeBranch;

        return PopScope(
          canPop: isDismissible,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                if (isDismissible)
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D4037).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF5D4037),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Cabang',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Pilih cabang operasional yang ingin dibuka',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDismissible)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.grey[600],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // List of branches
                if (branches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF5D4037),
                            strokeWidth: 2.5,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Memuat daftar cabang...',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: branches.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        final isSelected = activeBranch?.id == branch.id;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await auth.setActiveBranch(branch);
                              if (context.mounted) {
                                final cart = Provider.of<CartProvider>(
                                  context,
                                  listen: false,
                                );
                                await cart.refreshAll();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Berhasil beralih ke ${branch.name}',
                                    ),
                                    backgroundColor: const Color(0xFF5D4037),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF5D4037).withOpacity(0.06)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF5D4037)
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2.0 : 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF5D4037)
                                          : Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          branch.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? const Color(0xFF5D4037)
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (branch.address != null &&
                                            branch.address!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            branch.address!,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5D4037),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Aktif',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                if (!isDismissible) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => auth.logout(),
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text(
                      'Batal & Keluar Akun',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
