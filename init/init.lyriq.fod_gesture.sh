#!/vendor/bin/sh
# Mirror stock TouchHwAidlService touch gesture modes for Goodix FOD:
# zero tap + single/double tap wake (stock gesture_mode_type 0x07).
# gesture_store is one-toggle-per-write; the driver pushes the config to
# the touch IC when entering doze, so write everything as early as possible.

NODE=/sys/class/touchscreen/primary/gesture

i=0
while [ $i -lt 10 ]; do
    if [ -w $NODE ]; then
        echo 17 > $NODE && echo 33 > $NODE && echo 49 > $NODE && exit 0
    fi
    i=$((i + 1))
    sleep 1
done
exit 1
