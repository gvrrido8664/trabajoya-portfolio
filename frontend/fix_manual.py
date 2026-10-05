import os

file_path = "lib/features/admin/presentation/pages/admin_usuarios_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("Widget _field({", "Widget _field(BuildContext context, {")
content = content.replace("_field(", "_field(context, ")
# Wait, in the dialog builders, the context variable is 'ctx', not 'context'
# Let's fix that
content = content.replace("_field(context, \n                  controller: emailCtrl", "_field(ctx, \n                  controller: emailCtrl")
content = content.replace("_field(context, \n                  controller: passwordCtrl", "_field(ctx, \n                  controller: passwordCtrl")
content = content.replace("_field(context, controller: nombreCtrl", "_field(ctx, controller: nombreCtrl")
content = content.replace("_field(context, controller: apellidoCtrl", "_field(ctx, controller: apellidoCtrl")
content = content.replace("_field(context, \n                  controller: telefonoCtrl", "_field(ctx, \n                  controller: telefonoCtrl")

content = content.replace("Widget _dropdown<T>({", "Widget _dropdown<T>(BuildContext context, {")
content = content.replace("_dropdown(", "_dropdown(context, ")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

# Fix consts
files_to_fix = {
    "lib/features/chat/presentation/pages/chat_panel.dart": [753],
    "lib/features/public/presentation/pages/landing_screen.dart": [1205],
    "lib/features/servicios/presentation/pages/crear_editar_servicio_screen.dart": [1155],
}

for fp, lines in files_to_fix.items():
    with open(fp, "r", encoding="utf-8") as f:
        lines_content = f.readlines()
    for l in lines:
        idx = l - 1
        lines_content[idx] = lines_content[idx].replace("const ", "")
    with open(fp, "w", encoding="utf-8") as f:
        f.writelines(lines_content)

print("Done")
