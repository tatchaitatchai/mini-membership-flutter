import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../promotions/domain/promotion.dart';
import '../../../promotions/data/promotion_repository.dart';

class PromotionStepWidget extends ConsumerWidget {
  final Promotion? selectedPromotion;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Function(Promotion?) onPromotionSelected;

  const PromotionStepWidget({
    super.key,
    required this.selectedPromotion,
    required this.onBack,
    required this.onNext,
    required this.onPromotionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ขั้นตอนที่ 3: ใช้โปรโมชั่น (ถ้ามี)',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SecondaryButton(text: 'ย้อนกลับ', onPressed: onBack),
              const SizedBox(width: 16),
              PrimaryButton(text: 'ถัดไป', onPressed: onNext),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Promotion>>(
              future: ref.read(promotionRepositoryProvider).getActivePromotions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Card(
                        color: selectedPromotion == null ? Colors.blue.shade50 : null,
                        child: ListTile(
                          title: const Text('ไม่ใช้โปรโมชั่น'),
                          trailing: selectedPromotion == null ? const Icon(Icons.check, color: Colors.blue) : null,
                          onTap: () => onPromotionSelected(null),
                        ),
                      );
                    }

                    final promotion = snapshot.data![index - 1];
                    return Card(
                      color: selectedPromotion?.id == promotion.id ? Colors.blue.shade50 : null,
                      child: ListTile(
                        title: Text(promotion.name),
                        subtitle: Text(promotion.description),
                        trailing: selectedPromotion?.id == promotion.id
                            ? const Icon(Icons.check, color: Colors.blue)
                            : Text(promotion.displayValue),
                        onTap: () => onPromotionSelected(promotion),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
