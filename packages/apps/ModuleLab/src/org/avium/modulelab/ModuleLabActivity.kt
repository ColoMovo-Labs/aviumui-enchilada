package org.avium.modulelab

import android.content.Context
import android.os.Bundle
import android.os.PowerManager
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.button.MaterialButton
import com.google.android.material.color.DynamicColors
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.materialswitch.MaterialSwitch
import org.avium.modulelab.data.ModuleInfo
import org.avium.modulelab.ui.ModuleAdapter
import org.avium.modulelab.utils.ModuleScanner
import org.avium.modulelab.utils.RootDetector
import org.avium.modulelab.utils.SafeModeController
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class ModuleLabActivity : AppCompatActivity() {

    private lateinit var chipRootStatus: TextView
    private lateinit var textRootEngine: TextView
    private lateinit var textSelinuxMode: TextView
    private lateinit var textDataAdbStatus: TextView
    private lateinit var textZygiskStatus: TextView

    private lateinit var chipLsposedStatus: TextView
    private lateinit var chipVectorStatus: TextView

    private lateinit var switchSafeMode: MaterialSwitch
    private lateinit var btnDisableAll: MaterialButton
    private lateinit var btnRollbackLast: MaterialButton

    private lateinit var textModulesCount: TextView
    private lateinit var textEmptyModules: TextView
    private lateinit var recyclerModules: RecyclerView

    private lateinit var adapter: ModuleAdapter
    private var moduleList: MutableList<ModuleInfo> = mutableListOf()

    override fun onCreate(savedInstanceState: Bundle?) {
        DynamicColors.applyToActivitiesIfAvailable(application)
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_module_lab)

        initViews()
        setupListeners()
        refreshAll()
    }

    private fun initViews() {
        val toolbar: MaterialToolbar = findViewById(R.id.top_app_bar)
        toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.menu_refresh -> {
                    refreshAll()
                    Toast.makeText(this, R.string.action_refresh, Toast.LENGTH_SHORT).show()
                    true
                }
                R.id.menu_diagnostics -> {
                    showDiagnosticsDialog()
                    true
                }
                R.id.menu_reboot -> {
                    showRebootDialog()
                    true
                }
                else -> false
            }
        }

        chipRootStatus = findViewById(R.id.chip_root_status)
        textRootEngine = findViewById(R.id.text_root_engine)
        textSelinuxMode = findViewById(R.id.text_selinux_mode)
        textDataAdbStatus = findViewById(R.id.text_data_adb_status)
        textZygiskStatus = findViewById(R.id.text_zygisk_status)

        chipLsposedStatus = findViewById(R.id.chip_lsposed_status)
        chipVectorStatus = findViewById(R.id.chip_vector_status)

        switchSafeMode = findViewById(R.id.switch_safe_mode)
        btnDisableAll = findViewById(R.id.btn_disable_all)
        btnRollbackLast = findViewById(R.id.btn_rollback_last)

        textModulesCount = findViewById(R.id.text_modules_count)
        textEmptyModules = findViewById(R.id.text_empty_modules)
        recyclerModules = findViewById(R.id.recycler_modules)

        recyclerModules.layoutManager = LinearLayoutManager(this)
        adapter = ModuleAdapter(
            modules = moduleList,
            onToggle = { module, isEnabled ->
                ModuleScanner.setModuleEnabled(module, isEnabled)
                updateModulesHeader()
            },
            onDetails = { module ->
                showModuleDetailsDialog(module)
            },
            onRemove = { module ->
                showRemoveConfirmDialog(module)
            }
        )
        recyclerModules.adapter = adapter
    }

    private fun setupListeners() {
        switchSafeMode.setOnCheckedChangeListener { _, isChecked ->
            SafeModeController.setSafeMode(isChecked)
            val msg = if (isChecked) "Safe Mode enabled for next boot" else "Safe Mode disabled"
            Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
        }

        btnDisableAll.setOnClickListener {
            if (moduleList.isEmpty()) return@setOnClickListener
            MaterialAlertDialogBuilder(this)
                .setTitle(R.string.action_disable_all_modules)
                .setMessage(getString(R.string.action_disable_all_confirm, moduleList.size))
                .setPositiveButton(R.string.dialog_confirm) { _, _ ->
                    val disabledCount = SafeModeController.disableAllModules(moduleList)
                    adapter.notifyDataSetChanged()
                    updateModulesHeader()
                    Toast.makeText(this, "Disabled $disabledCount modules. Reboot required.", Toast.LENGTH_SHORT).show()
                }
                .setNegativeButton(R.string.dialog_cancel, null)
                .show()
        }

        btnRollbackLast.setOnClickListener {
            if (moduleList.isEmpty()) return@setOnClickListener
            val rolledBack = SafeModeController.rollbackLastInstalledModule(moduleList)
            if (rolledBack != null) {
                adapter.notifyDataSetChanged()
                updateModulesHeader()
                Toast.makeText(this, "Disabled newest module: ${rolledBack.name}", Toast.LENGTH_LONG).show()
            } else {
                Toast.makeText(this, "No modules found to rollback", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun refreshAll() {
        // 1. Root Environment
        val rootEnv = RootDetector.detectEnvironment()
        if (rootEnv.isRooted) {
            chipRootStatus.text = getString(R.string.root_status_active)
            chipRootStatus.setTextColor(ContextCompat.getColor(this, R.color.status_active_color))
            textRootEngine.text = "${rootEnv.engineName} ${rootEnv.versionString}".trim()
        } else {
            chipRootStatus.text = getString(R.string.root_status_inactive)
            chipRootStatus.setTextColor(ContextCompat.getColor(this, R.color.status_inactive_color))
            textRootEngine.text = rootEnv.engineName
        }

        if (rootEnv.isSELinuxEnforcing) {
            textSelinuxMode.text = getString(R.string.selinux_enforcing)
            textSelinuxMode.setTextColor(ContextCompat.getColor(this, R.color.status_active_color))
        } else {
            textSelinuxMode.text = getString(R.string.selinux_permissive)
            textSelinuxMode.setTextColor(ContextCompat.getColor(this, R.color.status_warning_color))
        }

        textDataAdbStatus.text = if (rootEnv.hasDataAdb) getString(R.string.status_detected) else getString(R.string.status_missing)
        textZygiskStatus.text = if (rootEnv.isZygiskEnabled) getString(R.string.status_enabled) else getString(R.string.status_disabled)
        textZygiskStatus.setTextColor(
            ContextCompat.getColor(this, if (rootEnv.isZygiskEnabled) R.color.status_active_color else R.color.status_inactive_color)
        )

        // 2. Hook Frameworks
        val frameworks = RootDetector.detectFrameworks(this)
        chipLsposedStatus.text = if (frameworks.isLSPosedActive) frameworks.lsposedVersion else getString(R.string.framework_inactive)
        chipLsposedStatus.setTextColor(
            ContextCompat.getColor(this, if (frameworks.isLSPosedActive) R.color.status_active_color else R.color.status_inactive_color)
        )

        chipVectorStatus.text = if (frameworks.isVectorActive) frameworks.vectorVersion else getString(R.string.framework_inactive)
        chipVectorStatus.setTextColor(
            ContextCompat.getColor(this, if (frameworks.isVectorActive) R.color.status_active_color else R.color.status_inactive_color)
        )

        // 3. Safe Mode
        switchSafeMode.isChecked = SafeModeController.isSafeModeActive()

        // 4. Modules
        moduleList = ModuleScanner.scanModules().toMutableList()
        adapter.updateModules(moduleList)
        updateModulesHeader()
    }

    private fun updateModulesHeader() {
        val total = moduleList.size
        val active = moduleList.count { it.isEnabled }
        textModulesCount.text = getString(R.string.modules_count_format, total, active)
        textEmptyModules.visibility = if (total == 0) View.VISIBLE else View.GONE
    }

    private fun showModuleDetailsDialog(module: ModuleInfo) {
        val view = layoutInflater.inflate(R.layout.dialog_module_details, null)
        val title: TextView = view.findViewById(R.id.dialog_title)
        val idText: TextView = view.findViewById(R.id.dialog_id)
        val meta: TextView = view.findViewById(R.id.dialog_meta_content)
        val log: TextView = view.findViewById(R.id.dialog_log_content)

        title.text = module.name
        idText.text = "ID: ${module.id}"
        meta.text = "Version: ${module.version} (${module.versionCode})\nAuthor: ${module.author}\nPath: ${module.path}\nStatus: ${if (module.isEnabled) "Active" else "Disabled"}"

        log.text = module.serviceLog ?: "No execution logs recorded for this module."

        MaterialAlertDialogBuilder(this)
            .setView(view)
            .setPositiveButton(R.string.action_close, null)
            .show()
    }

    private fun showRemoveConfirmDialog(module: ModuleInfo) {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.module_remove_confirm_title)
            .setMessage(getString(R.string.module_remove_confirm_message, module.name))
            .setPositiveButton(R.string.dialog_confirm) { _, _ ->
                ModuleScanner.markModuleRemove(module, true)
                module.isPendingRemove = true
                module.isNeedReboot = true
                adapter.notifyDataSetChanged()
                Toast.makeText(this, "Module marked for removal on next reboot", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.dialog_cancel, null)
            .show()
    }

    private fun showDiagnosticsDialog() {
        val report = StringBuilder()
        report.append("=== Module Lab Diagnostics ===\n")
        report.append("Build: AviumUI 16.2.2 (enchilada)\n")
        val env = RootDetector.detectEnvironment()
        report.append("Root: ${env.engineName} (${env.versionString})\n")
        report.append("Su Path: ${env.suPath}\n")
        report.append("SELinux: ${if (env.isSELinuxEnforcing) "Enforcing" else "Permissive"}\n")
        report.append("/data/adb exists: ${env.hasDataAdb}\n")
        report.append("Zygisk active: ${env.isZygiskEnabled}\n\n")

        val magiskLog = File("/data/adb/magisk.log")
        if (magiskLog.exists()) {
            report.append("--- Last 15 lines of magisk.log ---\n")
            val lines = runCatching { magiskLog.readLines().takeLast(15) }.getOrDefault(emptyList())
            lines.forEach { report.append(it).append("\n") }
        } else {
            report.append("magisk.log not found at /data/adb/magisk.log\n")
        }

        val textView = TextView(this).apply {
            setPadding(32, 24, 32, 24)
            typeface = android.graphics.Typeface.MONOSPACE
            textSize = 12f
            text = report.toString()
        }

        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.dialog_diagnostics_title)
            .setView(textView)
            .setPositiveButton(R.string.action_close, null)
            .show()
    }

    private fun showRebootDialog() {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.reboot_confirm_title)
            .setMessage(R.string.reboot_confirm_message)
            .setPositiveButton(R.string.dialog_confirm) { _, _ ->
                try {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    pm.reboot(null)
                } catch (e: Exception) {
                    Toast.makeText(this, "Reboot permission error: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
            .setNegativeButton(R.string.dialog_cancel, null)
            .show()
    }
}
