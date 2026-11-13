package app.mediarr.mediarr.backup

import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Keeps a secret, such as a device key, in SharedPreferences, encrypted with a key that never
 * leaves the Android Keystore. A value an older version stored in plain text is encrypted the
 * first time it is read. Should the Keystore fail on some phone, the value stays as it was rather
 * than being lost: backup working matters more.
 */
object SecretStore {
    private const val ALIAS = "mediarr-secrets"
    private const val PREFIX = "ks1:"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val IV_BYTES = 12
    private const val TAG_BITS = 128
    private val lock = Any()

    /** The secret, or null if there is none or it can no longer be decrypted. */
    fun read(prefs: SharedPreferences, name: String): String? {
        val stored = prefs.getString(name, null) ?: return null
        if (stored.startsWith(PREFIX)) return decrypt(stored.removePrefix(PREFIX))
        // From an older version. Replaced only if it reads back the same, and only if nothing
        // else was stored meanwhile.
        val sealed = encrypt(stored)
        if (sealed != null && decrypt(sealed) == stored) {
            synchronized(lock) {
                val unchanged = prefs.getString(name, null) == stored
                if (unchanged) prefs.edit().putString(name, PREFIX + sealed).commit()
                Unit
            }
        }
        return stored
    }

    fun write(prefs: SharedPreferences, name: String, value: String) {
        val sealed = encrypt(value)?.takeIf { decrypt(it) == value }
        synchronized(lock) {
            prefs.edit().putString(name, if (sealed != null) PREFIX + sealed else value).commit()
            Unit
        }
    }

    /** Made once; the lock keeps two threads from each making one and losing the other's. */
    private fun key(): SecretKey = synchronized(lock) {
        val keys = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        keys.getKey(ALIAS, null) as? SecretKey ?: generate()
    }

    private fun generate(): SecretKey {
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private fun encrypt(value: String): String? =
        try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, key())
            val iv = cipher.iv
            if (iv.size != IV_BYTES) {
                null
            } else {
                Base64.encodeToString(iv + cipher.doFinal(value.toByteArray(Charsets.UTF_8)), Base64.NO_WRAP)
            }
        } catch (_: Exception) {
            null
        }

    private fun decrypt(sealed: String): String? =
        try {
            val bytes = Base64.decode(sealed, Base64.NO_WRAP)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(
                Cipher.DECRYPT_MODE,
                key(),
                GCMParameterSpec(TAG_BITS, bytes.copyOfRange(0, IV_BYTES)),
            )
            String(cipher.doFinal(bytes, IV_BYTES, bytes.size - IV_BYTES), Charsets.UTF_8)
        } catch (_: Exception) {
            null
        }
}
