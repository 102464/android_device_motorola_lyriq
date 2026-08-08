/*
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/strings.h>
#include <android/binder_interface_utils.h>
#include <cstdlib>
#include <health-impl/Health.h>
#include <health/utils.h>

#ifndef CHARGER_FORCE_NO_UI
#define CHARGER_FORCE_NO_UI 0
#endif

#if !CHARGER_FORCE_NO_UI
#include <health-impl/ChargerUtils.h>
#endif

using aidl::android::hardware::health::HalHealthLoop;
using aidl::android::hardware::health::Health;
using aidl::android::hardware::health::HealthInfo;

#if !CHARGER_FORCE_NO_UI
using aidl::android::hardware::health::charger::ChargerCallback;
using aidl::android::hardware::health::charger::ChargerModeMain;
#endif

static constexpr const char* gInstanceName = "default";
static constexpr std::string_view gChargerArg{"--charger"};

static constexpr const char* kChargeRatePath = "/sys/class/power_supply/battery/charge_rate";
static constexpr const char* kVbusVoltagePath =
        "/sys/class/power_supply/mtk-master-charger/voltage_now";

namespace aidl::android::hardware::health {

class LyriqHealth : public Health {
  public:
    using Health::Health;

  protected:
    void UpdateHealthInfo(HealthInfo* health_info) override {
        // mt6360 hardcodes current_max to 500mA and has no voltage_max, so the
        // computed maxChargingWattage is always 2.5W and SystemUI reports
        // "charging slowly" even during TurboCharge. The kernel already
        // classifies the negotiated rate in charge_rate ("Turbo" = PD/PPS or
        // Rp 3A); report a realistic wattage from that instead.
        std::string rate;
        if (::android::base::ReadFileToString(kChargeRatePath, &rate) &&
            ::android::base::Trim(rate) == "Turbo") {
            int64_t vbus_uv = 11000000;
            std::string vbus;
            if (::android::base::ReadFileToString(kVbusVoltagePath, &vbus)) {
                // mtk-master-charger reports VBUS in mV.
                long vbus_mv = atol(::android::base::Trim(vbus).c_str());
                if (vbus_mv > 5000) {
                    vbus_uv = static_cast<int64_t>(vbus_mv) * 1000;
                }
            }
            health_info->maxChargingVoltageMicrovolts = vbus_uv;
            health_info->maxChargingCurrentMicroamps = 3000000;
        }

        // The kernel time_to_full_now explodes near full charge because the
        // taper current approaches zero (observed: 4 days at 99%). Recompute
        // from the actual remaining charge and average current; fall back to
        // the BatteryStats algorithm when data is unavailable.
        if (health_info->batteryLevel >= 100) {
            health_info->batteryChargeTimeToFullNowSeconds = 0;
        } else if (health_info->batteryCurrentAverageMicroamps > 0 &&
                   health_info->batteryFullChargeUah > health_info->batteryChargeCounterUah) {
            int64_t remain_uah =
                    health_info->batteryFullChargeUah - health_info->batteryChargeCounterUah;
            health_info->batteryChargeTimeToFullNowSeconds =
                    remain_uah * 3600 / health_info->batteryCurrentAverageMicroamps;
        } else {
            health_info->batteryChargeTimeToFullNowSeconds = -1;
        }
    }
};

#if !CHARGER_FORCE_NO_UI
class ChargerCallbackImpl : public ChargerCallback {
  public:
    using ChargerCallback::ChargerCallback;
    bool ChargerEnableSuspend() override { return true; }
};
#endif

}  // namespace aidl::android::hardware::health

int main(int argc, char** argv) {
#ifdef __ANDROID_RECOVERY__
    android::base::InitLogging(argv, android::base::KernelLogger);
#endif

    auto config = std::make_unique<healthd_config>();
    ::android::hardware::health::InitHealthdConfig(config.get());
    auto binder = ndk::SharedRefBase::make<aidl::android::hardware::health::LyriqHealth>(
            gInstanceName, std::move(config));

    if (argc >= 2 && argv[1] == gChargerArg) {
#if !CHARGER_FORCE_NO_UI
        return ChargerModeMain(
                binder,
                std::make_shared<aidl::android::hardware::health::ChargerCallbackImpl>(binder));
#endif

        LOG(INFO) << "Starting charger mode without UI.";
    } else {
        LOG(INFO) << "Starting health HAL.";
    }

    auto hal_health_loop = std::make_shared<HalHealthLoop>(binder, binder);
    return hal_health_loop->StartLoop();
}
