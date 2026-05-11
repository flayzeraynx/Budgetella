package com.budgetella.app.data.local

import androidx.room.TypeConverter

/**
 * Room TypeConverters for fields that aren't primitives.
 *
 * Currently only [List]<String> ↔ String for the User.roles field. Everything
 * else in the schema is already a Room-supported primitive (Long for dates +
 * money, String for enums + UUIDs, Boolean, Int, Double).
 */
object Converters {

    private const val ROLES_DELIMITER = ","

    @TypeConverter
    @JvmStatic
    fun rolesToString(roles: List<String>?): String =
        roles?.joinToString(ROLES_DELIMITER) ?: ""

    @TypeConverter
    @JvmStatic
    fun stringToRoles(stored: String?): List<String> =
        stored
            ?.split(ROLES_DELIMITER)
            ?.map { it.trim() }
            ?.filter { it.isNotEmpty() }
            ?: emptyList()
}
