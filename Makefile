ASM=nasm
CC=gcc

SRC_DIR=src
BUILD_DIR=build

.PHONY: all clean always

floppy: $(BUILD_DIR)/hard_drive.img

$(BUILD_DIR)/hard_drive.img: $(BUILD_DIR)/bootloader.bin $(BUILD_DIR)/loader.bin
	dd if=/dev/zero of=$(BUILD_DIR)/hard_drive.img bs=512 count=69632

	# Write bootloader to sector 0
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/hard_drive.img bs=512 count=1 conv=notrunc

	# Write loader to sector 1 (NOT append!)
	dd if=$(BUILD_DIR)/loader.bin of=$(BUILD_DIR)/hard_drive.img bs=512 seek=1 conv=notrunc

	chmod 666 $(BUILD_DIR)/hard_drive.img
	chmod 777 $(BUILD_DIR)


$(BUILD_DIR)/bootloader.bin: always
	$(ASM) -f bin $(SRC_DIR)/bootloader/boot.asm -o $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/loader.bin: always
	nasm $(SRC_DIR)/loader.asm -f bin -o $(BUILD_DIR)/loader.bin

always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
