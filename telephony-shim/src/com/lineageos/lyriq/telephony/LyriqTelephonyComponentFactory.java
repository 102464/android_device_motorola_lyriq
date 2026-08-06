/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package com.lineageos.lyriq.telephony;

import android.content.Context;
import android.telephony.TelephonyManager;
import android.util.Log;

import com.android.internal.telephony.CommandsInterface;
import com.android.internal.telephony.HalVersion;
import com.android.internal.telephony.Phone;
import com.android.internal.telephony.RIL;
import com.android.internal.telephony.TelephonyComponentFactory;
import com.android.internal.telephony.flags.FeatureFlags;

import java.lang.reflect.Array;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

/**
 * AOSP components plus the MotoOemRIL companion and the
 * MtkMotoExtTelephonyService that mtkfusionrild expects as its
 * framework add-on. Without the service the modem keeps the
 * eSIM slot absent.
 */
public class LyriqTelephonyComponentFactory extends TelephonyComponentFactory {
    private static final String TAG = "LyriqTelephonyComponentFactory";
    private static final String MOTO_OEM_RIL_CLASS =
            "com.motorola.android.internal.telephony.MotoOemRIL";
    private static final String MOTO_EXT_SERVICE_CLASS =
            "com.motorola.android.internal.telephony.MtkMotoExtTelephonyService";

    private static Object[] sMotoOemRILs;

    @Override
    public RIL makeRIL(Context context, int preferredNetworkType, int cdmaSubscription,
            Integer instanceId, FeatureFlags featureFlags) {
        RIL ril = super.makeRIL(context, preferredNetworkType, cdmaSubscription, instanceId,
                featureFlags);
        try {
            synchronized (LyriqTelephonyComponentFactory.class) {
                if (sMotoOemRILs == null) {
                    sMotoOemRILs =
                            new Object[TelephonyManager.getDefault().getActiveModemCount()];
                }
                if (instanceId < sMotoOemRILs.length && sMotoOemRILs[instanceId] == null) {
                    Class<?> cls = Class.forName(MOTO_OEM_RIL_CLASS);
                    Constructor<?> ctor = cls.getConstructor(Context.class, Integer.class,
                            HalVersion.class);
                    sMotoOemRILs[instanceId] = ctor.newInstance(context, instanceId,
                            ril.getHalVersion(TelephonyManager.HAL_SERVICE_RADIO));
                    Log.i(TAG, "MotoOemRIL created for phone " + instanceId);
                }
            }
        } catch (Throwable t) {
            Log.e(TAG, "Failed to create MotoOemRIL", t);
        }
        return ril;
    }

    @Override
    public void makeExtTelephonyClasses(Context context, Phone[] phones,
            CommandsInterface[] commandsInterfaces) {
        super.makeExtTelephonyClasses(context, phones, commandsInterfaces);
        try {
            synchronized (LyriqTelephonyComponentFactory.class) {
                if (sMotoOemRILs == null) {
                    Log.e(TAG, "MotoOemRILs not ready, skip ext telephony init");
                    return;
                }
                for (Object oemRil : sMotoOemRILs) {
                    if (oemRil == null) {
                        Log.e(TAG, "Incomplete MotoOemRILs, skip ext telephony init");
                        return;
                    }
                }
                Class<?> rilCls = Class.forName(MOTO_OEM_RIL_CLASS);
                Object oemRils = Array.newInstance(rilCls, sMotoOemRILs.length);
                for (int i = 0; i < sMotoOemRILs.length; i++) {
                    Array.set(oemRils, i, sMotoOemRILs[i]);
                }
                Class<?> svcCls = Class.forName(MOTO_EXT_SERVICE_CLASS);
                Method init = svcCls.getMethod("init", Context.class, oemRils.getClass());
                init.invoke(null, context, oemRils);
                Log.i(TAG, "MtkMotoExtTelephonyService initialized");
            }
        } catch (Throwable t) {
            Log.e(TAG, "Failed to init MtkMotoExtTelephonyService", t);
        }
    }
}
