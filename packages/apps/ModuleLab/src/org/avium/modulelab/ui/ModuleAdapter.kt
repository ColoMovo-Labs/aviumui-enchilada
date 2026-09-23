package org.avium.modulelab.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.google.android.material.materialswitch.MaterialSwitch
import org.avium.modulelab.R
import org.avium.modulelab.data.ModuleInfo

class ModuleAdapter(
    private var modules: List<ModuleInfo>,
    private val onToggle: (ModuleInfo, Boolean) -> Unit,
    private val onDetails: (ModuleInfo) -> Unit,
    private val onRemove: (ModuleInfo) -> Unit
) : RecyclerView.Adapter<ModuleAdapter.ViewHolder>() {

    fun updateModules(newModules: List<ModuleInfo>) {
        this.modules = newModules
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_module_card, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = modules[position]
        holder.bind(item)
    }

    override fun getItemCount(): Int = modules.size

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val textName: TextView = itemView.findViewById(R.id.text_module_name)
        private val textMeta: TextView = itemView.findViewById(R.id.text_module_meta)
        private val textDesc: TextView = itemView.findViewById(R.id.text_module_description)
        private val switchEnabled: MaterialSwitch = itemView.findViewById(R.id.switch_module_enabled)
        private val chipState: TextView = itemView.findViewById(R.id.chip_module_state)
        private val chipReboot: TextView = itemView.findViewById(R.id.chip_reboot_required)
        private val chipRemove: TextView = itemView.findViewById(R.id.chip_pending_remove)
        private val btnDetails: MaterialButton = itemView.findViewById(R.id.btn_module_details)
        private val btnRemove: ImageButton = itemView.findViewById(R.id.btn_module_remove)

        fun bind(module: ModuleInfo) {
            val ctx = itemView.context
            textName.text = module.name
            textMeta.text = "${module.version} (${module.versionCode}) • ${module.author}"
            textDesc.text = if (module.description.isNotEmpty()) module.description else ctx.getString(R.string.app_summary)

            switchEnabled.setOnCheckedChangeListener(null)
            switchEnabled.isChecked = module.isEnabled

            if (module.isEnabled) {
                chipState.text = ctx.getString(R.string.module_badge_enabled)
                chipState.setTextColor(ContextCompat.getColor(ctx, R.color.status_active_color))
            } else {
                chipState.text = ctx.getString(R.string.module_badge_disabled)
                chipState.setTextColor(ContextCompat.getColor(ctx, R.color.status_inactive_color))
            }

            chipReboot.visibility = if (module.isNeedReboot) View.VISIBLE else View.GONE
            chipRemove.visibility = if (module.isPendingRemove) View.VISIBLE else View.GONE

            switchEnabled.setOnCheckedChangeListener { _, isChecked ->
                module.isNeedReboot = true
                onToggle(module, isChecked)
                bind(module)
            }

            btnDetails.setOnClickListener { onDetails(module) }
            btnRemove.setOnClickListener { onRemove(module) }
        }
    }
}
