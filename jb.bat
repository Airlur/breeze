:: 创建主要目录
mkdir lib\config
mkdir lib\models
mkdir lib\screens\home\widgets
mkdir lib\screens\qr
mkdir lib\widgets\messages
mkdir lib\widgets\common
mkdir lib\widgets\input
mkdir lib\services\local
mkdir lib\services\network
mkdir lib\services\utils
mkdir lib\utils\extensions
mkdir lib\utils\helpers

:: 创建配置文件
type nul > lib\config\theme.dart
type nul > lib\config\constants.dart
type nul > lib\config\app_config.dart

:: 创建模型文件
type nul > lib\models\message.dart
type nul > lib\models\text_message.dart
type nul > lib\models\file_message.dart

:: 创建页面文件
type nul > lib\screens\home\home_screen.dart
type nul > lib\screens\home\home_controller.dart
type nul > lib\screens\qr\qr_scanner_screen.dart
type nul > lib\screens\qr\qr_result_dialog.dart

:: 创建组件文件
type nul > lib\widgets\messages\message_item.dart
type nul > lib\widgets\messages\text_message_item.dart
type nul > lib\widgets\messages\file_message_item.dart
type nul > lib\widgets\common\loading_indicator.dart
type nul > lib\widgets\common\custom_dialog.dart
type nul > lib\widgets\common\toast.dart
type nul > lib\widgets\input\message_input.dart
type nul > lib\widgets\input\file_picker.dart

:: 创建服务文件
type nul > lib\services\local\storage_service.dart
type nul > lib\services\local\db_service.dart
type nul > lib\services\network\network_service.dart
type nul > lib\services\network\api_service.dart
type nul > lib\services\utils\qr_service.dart
type nul > lib\services\utils\file_service.dart

:: 创建工具文件
type nul > lib\utils\extensions\date_extension.dart
type nul > lib\utils\extensions\string_extension.dart
type nul > lib\utils\helpers\file_helper.dart
type nul > lib\utils\helpers\message_helper.dart
type nul > lib\utils\logger.dart