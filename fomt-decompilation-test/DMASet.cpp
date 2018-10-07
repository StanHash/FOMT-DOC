
typedef unsigned int uintptr_t;

extern "C" void DmaSet(
	unsigned source,
	unsigned target,
	unsigned control,
	void* target_dma
);

extern int pDMA3[];

void Dma3Copy(const void* pSource, void* pTarget, unsigned size) {
	if (!pSource || !pTarget)
		return;
	
	if (((uintptr_t)(pSource) | (uintptr_t)(pTarget) | size) % 2) {
		if (((uintptr_t)(pSource) | (uintptr_t)(pTarget) | size) % 4) {
			DmaSet(
				(uintptr_t)(pSource),
				(uintptr_t)(pTarget),
				0x84000000 | (unsigned short)(size / 4),
				pDMA3
			);
		} else {
			DmaSet(
				(uintptr_t)(pSource),
				(uintptr_t)(pTarget),
				0x80000000 | (unsigned short)(size / 2),
				pDMA3
			);
		}
	} else {
		DmaSet(
			(uintptr_t)(pSource),
			(uintptr_t)(pTarget),
			0,
			pDMA3
		);
	}
}
