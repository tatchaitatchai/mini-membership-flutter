import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../shift/data/shift_repository.dart';
import '../../../shift/data/models/shift_models.dart';

class SelectBranchScreen extends ConsumerStatefulWidget {
  const SelectBranchScreen({super.key});

  @override
  ConsumerState<SelectBranchScreen> createState() => _SelectBranchScreenState();
}

class _SelectBranchScreenState extends ConsumerState<SelectBranchScreen> {
  List<BranchInfo> _branches = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final shiftRepo = ref.read(shiftRepositoryProvider);
    final branches = await shiftRepo.getBranches();

    if (!mounted) return;

    if (branches.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่พบสาขา กรุณาติดต่อผู้ดูแลระบบ';
      });
    } else {
      setState(() {
        _branches = branches;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSelectBranch() async {
    if (_selectedBranchId == null) return;

    setState(() => _isLoading = true);

    final shiftRepo = ref.read(shiftRepositoryProvider);
    final result = await shiftRepo.selectBranch(_selectedBranchId!);
    if (!mounted) return;

    if (result != null) {
      if (result.isShiftOpened) {
        context.go('/pin');
      } else {
        context.go('/open-shift');
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่สามารถเลือกสาขาได้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isSmall ? 20 : 32,
            right: isSmall ? 20 : 32,
            top: isSmall ? 20 : 32,
            bottom: (isSmall ? 20 : 32) + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.store, size: isSmall ? 56 : 80, color: const Color(0xFF6366F1)),
                SizedBox(height: isSmall ? 16 : 24),
                Text(
                  'เลือกสาขา',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isSmall ? 24 : 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'กรุณาเลือกสาขาที่ต้องการเข้าใช้งาน',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isSmall ? 14 : 16, color: Colors.grey.shade600),
                ),
                SizedBox(height: isSmall ? 32 : 48),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: [
                      ..._branches.map((branch) => _buildBranchTile(branch)),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'ดำเนินการต่อ',
                        onPressed: _selectedBranchId != null ? _handleSelectBranch : null,
                        isLoading: _isLoading,
                        fullWidth: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranchTile(BranchInfo branch) {
    final isSelected = _selectedBranchId == branch.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedBranchId = branch.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          branch.isShiftOpened ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: branch.isShiftOpened ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          branch.isShiftOpened ? 'กะเปิดอยู่' : 'ยังไม่เปิดกะ',
                          style: TextStyle(fontSize: 12, color: branch.isShiftOpened ? Colors.green : Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
