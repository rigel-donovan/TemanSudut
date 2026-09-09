import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/branch.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('res/videos/sudut_kopi.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isSelectingBranch = auth.isAuthenticated && auth.activeBranch == null;

    final cardContent = isSelectingBranch
        ? _buildBranchSelectionContent(auth)
        : _buildLoginFormContent();

    final formCard = SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.all(24.0),
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: cardContent,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > 700;

          if (isLandscape) {
            return Row(
              children: [
                // Video Section (Kiri)
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22.5),
                        child: _videoController.value.isInitialized
                            ? SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController.value.size.width,
                                    height: _videoController.value.size.height,
                                    child: VideoPlayer(_videoController),
                                  ),
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                // Login / Branch Section (Kanan)
                Expanded(flex: 4, child: Center(child: formCard)),
              ],
            );
          }

          // Fallback portrait
          return Center(child: formCard);
        },
      ),
    );
  }

  Widget _buildLoginFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo
        Center(
          child: Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'res/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.storefront,
                  size: 45,
                  color: Colors.black26,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'TemanSudut',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Selamat datang kembali!\nSilakan masuk ke akun Anda.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Form Fields
        _buildTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: true,
        ),

        const SizedBox(height: 30),

        // Login Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Masuk Sekarang',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Footer
        Center(
          child: Text(
            'v2.3.0 TemanSudut POS',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchSelectionContent(AuthProvider auth) {
    final userName = auth.user?['name'] ?? 'Kasir';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF5D4037),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pilih Cabang Bertugas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Halo $userName, silakan tentukan cabang tempat Anda beroperasi hari ini.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        if (auth.branches.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5D4037),
                strokeWidth: 2.5,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollException(),
            itemCount: auth.branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final branch = auth.branches[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    setState(() => _isLoading = true);
                    await auth.setActiveBranch(branch);
                    if (mounted) {
                      final cart = Provider.of<CartProvider>(context, listen: false);
                      await cart.refreshAll();
                      setState(() => _isLoading = false);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D4037).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF5D4037),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (branch.address != null && branch.address!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  branch.address!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 20),

        TextButton.icon(
          onPressed: () => auth.logout(),
          icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.red),
          label: Text(
            'Ganti Akun Lain',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Masukkan $label Anda',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: Colors.black45),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.login(_emailCtrl.text, _passCtrl.text);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login gagal. Silakan cek kembali akun Anda.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
