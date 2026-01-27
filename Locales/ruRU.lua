local _, addonTable = ...
-- Translator ZamestoTV
local baseLocale = {
    -- General
    ["OKAY"] = OKAY,
    ["CLOSE"] = CLOSE,
    ["CANCEL"] = CANCEL,

    -- Import / Export errors
    ["EXPORT"] = "Экспорт",
    ["EXPORT_BAR"] = "Экспортировать эту полосу",
    ["IMPORT"] = "Импорт",
    ["IMPORT_BAR"] = "Импортировать эту полосу",
    ["EXPORT_FAILED"] = "Экспорт не удался.",
    ["IMPORT_FAILED_WITH_ERROR"] = "Импорт не удался, ошибка: ",
    ["IMPORT_STRING_NOT_SUITABLE"] = "Эта строка импорта не подходит для",
    ["IMPORT_STRING_OLDER_VERSION"] = "Эта строка импорта предназначена для более старой версии",
    ["IMPORT_STRING_INVALID"] = "Неверная строка импорта",
    ["IMPORT_DECODE_FAILED"] = "Декодирование не удалось",
    ["IMPORT_DECOMPRESSION_FAILED"] = "Распаковка не удалась",
    ["IMPORT_DESERIALIZATION_FAILED"] = "Десериализация не удалась",

    -- Settings (Esc > Options > AddOns)
    ["SETTINGS_HEADER_POWER_COLORS"] = "Цвета ресурсов",
    ["SETTINGS_HEADER_HEALTH_COLOR"] = "Цвет здоровья",
    ["SETTINGS_CATEGORY_IMPORT_EXPORT"] = "Импорт / Экспорт",
    ["SETTINGS_IMPORT_EXPORT_TEXT_1"] = "Созданные здесь строки экспорта включают все полосы текущей раскладки режима редактирования.\nЕсли нужно экспортировать только одну конкретную полосу, используйте кнопку Экспорт в настройках полосы в режиме редактирования.",
    ["SETTINGS_IMPORT_EXPORT_TEXT_2"] = "Кнопка импорта ниже поддерживает как глобальные строки, так и строки отдельных полос. Кнопка в настройках каждой полосы в режиме редактирования работает только с этой конкретной полосой.\nНапример, если вы экспортировали все полосы, но хотите импортировать только полосу основного ресурса, используйте кнопку импорта именно в настройках полосы основного ресурса в режиме редактирования.",
    ["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"] = "Экспорт. только цвета ресурсов",
    ["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"] = "Экспорт. с цветами ресурсов",
    ["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"] = "Экспорт. без цветов ресурсов",
    ["SETTINGS_BUTTON_IMPORT"] = "Импорт",
    ["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"] = "Настройки откроются после выхода из режима редактирования",

    -- Power
    ["HEALTH"] = HEALTH,
    ["MANA"] = POWER_TYPE_MANA,
    ["RAGE"] = POWER_TYPE_RED_POWER,
    ["WHIRLWIND"] = "Вихрь",
    ["FOCUS"] = POWER_TYPE_FOCUS,
    ["TIP_OF_THE_SPEAR"] = "Наконечник копья",
    ["ENERGY"]= POWER_TYPE_ENERGY,
    ["RUNIC_POWER"]= POWER_TYPE_RUNIC_POWER,
    ["LUNAR_POWER"]= POWER_TYPE_LUNAR_POWER,
    ["MAELSTORM"]= POWER_TYPE_MAELSTROM,
    ["MAELSTROM_WEAPON"] = "Оружие Водоворота",
    ["INSANITY"]= POWER_TYPE_INSANITY,
    ["FURY"]= POWER_TYPE_FURY_DEMONHUNTER,
    ["BLOOD_RUNE"]= COMBAT_TEXT_RUNE_BLOOD,
    ["FROST_RUNE"]= COMBAT_TEXT_RUNE_FROST,
    ["UNHOLY_RUNE"]= COMBAT_TEXT_RUNE_UNHOLY,
    ["COMBO_POINTS"] = COMBO_POINTS,
    ["OVERCHARGED_COMBO_POINTS"] = "Перегруженные комбо очки",
    ["SOUL_SHARDS"] = SOUL_SHARDS,
    ["HOLY_POWER"] = HOLY_POWER,
    ["CHI"] = CHI,
    ["STAGGER_LOW"] = "Слабое пошатывание",
    ["STAGGER_MEDIUM"] = "Среднее пошатывание",
    ["STAGGER_HIGH"] = "Сильное пошатывание",
    ["ARCANE_CHARGES"] = POWER_TYPE_ARCANE_CHARGES,
    ["SOUL_FRAGMENTS_VENGEANCE"] = "Фрагменты души (Месть)",
    ["SOUL_FRAGMENTS_DDH"] = "Фрагменты души (Пожиратель)",
    ["SOUL_FRAGMENTS_VOID_META"] = "Фрагменты души (Пожиратель - Метаморфоза Бездны)",
    ["ESSENCE"] = POWER_TYPE_ESSENCE,
    ["EBON_MIGHT"] = "Черная мощь",

    -- Bar names
    ["HEALTH_BAR_EDIT_MODE_NAME"] = "Полоса здоровья",
    ["PRIMARY_POWER_BAR_EDIT_MODE_NAME"] = "Полоса основного ресурса",
    ["SECONDARY_POWER_BAR_EDIT_MODE_NAME"] = "Полоса вторичного ресурса",
    ["TERNARY_POWER_BAR_EDIT_MODE_NAME"] = "Полоса Черной мощи",

    -- Bar visibility category - Edit Mode
    ["CATEGORY_BAR_VISIBILITY"] = "Видимость полосы",
    ["BAR_VISIBLE"] = "Полоса видна",
    ["BAR_STRATA"] = "Слой полосы",
    ["BAR_STRATA_TOOLTIP"] = "Слой, на котором отрисовывается полоса",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE"] = "Скрывать при использовании транспорта",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"] = "Включает формы передвижения друида",
    ["HIDE_MANA_ON_ROLE"] = "Скрывать ману по роли",
    ["HIDE_HEALTH_ON_ROLE"] = "Скрывать здоровье по роли",
    ["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"] = "Не работает на магах в спец. Тайная магия",
    ["HIDE_BLIZZARD_UI"] = "Скрывать интерфейс Blizzard",
    ["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"] = "Скрывает стандартный фрейм игрока Blizzard",
    ["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"] = "Скрывает стандартный интерфейс вторичного ресурса Blizzard (например, руны рыцаря смерти)",

    -- Position & Size category - Edit Mode
    ["CATEGORY_POSITION_AND_SIZE"] = "Позиция и размер",
    ["POSITION"] = "Позиция",
    ["X_POSITION"] = "Позиция по X",
    ["Y_POSITION"] = "Позиция по Y",
    ["RELATIVE_FRAME"] = "Относ. фрейм",
    ["RELATIVE_FRAME_TOOLTIP"] = "Из-за ограничений нельзя перетаскивать фрейм, если он привязан не к UIParent. Используйте ползунки X/Y",
    ["RELATIVE_FRAME_CYLIC_WARNING"] = "Нельзя изменить относительный фрейм: выбранный фрейм уже привязан к текущему фрейму.",
    ["ANCHOR_POINT"] = "Точка привязки",
    ["RELATIVE_POINT"] = "Относ. точка",
    ["BAR_SIZE"] = "Размер полосы",
    ["WIDTH_MODE"] = "Режим ширины",
    ["WIDTH"] = "Ширина",
    ["MINIMUM_WIDTH"] = "Минимальная ширина",
    ["MINIMUM_WIDTH_TOOLTIP"] = "0 = отключить. Работает только при синхронизации с менеджером перезарядки",
    ["HEIGHT"] = "Высота",

    -- Bar settings category - Edit Mode
    ["CATEGORY_BAR_SETTINGS"] = "Настройки полосы",
    ["FILL_DIRECTION"] = "Направление заполнения",
    ["FASTER_UPDATES"] = "Быстрые обновления (выше нагрузка на ЦПУ)",
    ["SMOOTH_PROGRESS"] = "Плавный прогресс",
    ["SHOW_TICKS_WHEN_AVAILABLE"] = "Показывать тики, когда доступно",
    ["TICK_THICKNESS"] = "Толщина тиков",

    -- Bar style category - Edit Mode
    ["CATEGORY_BAR_STYLE"] = "Стиль полосы",
    ["USE_CLASS_COLOR"] = "Использовать цвет класса",
    ["USE_RESOURCE_TEXTURE_AND_COLOR"] = "Использовать текстуру и цвет ресурса",
    ["BAR_TEXTURE"] = "Текстура полосы",
    ["BACKGROUND"] = "Фон",
    ["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"] = "Использовать цвет полосы для фона",
    ["BORDER"] = "Граница",

    -- Text settings category - Edit Mode
    ["CATEGORY_TEXT_SETTINGS"] = "Настройки текста",
    ["SHOW_RESOURCE_NUMBER"] = "Показывать числовое значение ресурса",
    ["RESOURCE_NUMBER_FORMAT"] = "Формат",
    ["RESOURCE_NUMBER_FORMAT_TOOLTIP"] = "Некоторые ресурсы не поддерживают формат в процентах",
    ["RESOURCE_NUMBER_PRECISION"] = "Точность",
    ["RESOURCE_NUMBER_ALIGNMENT"] = "Выравнивание",
    ["SHOW_MANA_AS_PERCENT"] = "Показывать ману в процентах",
    ["SHOW_MANA_AS_PERCENT_TOOLTIP"] = "Принудительно использовать формат процентов для маны",
    ["SHOW_RESOURCE_CHARGE_TIMER"] = "Показывать таймер зарядов ресурса (например, руны)",
    ["CHARGE_TIMER_PRECISION"] = "Точность таймера зарядов",

    -- Font category - Edit Mode
    ["CATEGORY_FONT"] = "Шрифт",
    ["FONT"] = "Шрифт",
    ["FONT_SIZE"] = "Размер",
    ["FONT_OUTLINE"] = "Обводка",

    -- Other
    ["POWER_COLOR_SETTINGS"] = "Настройки цветов ресурса",    
}

addonTable:RegisterLocale("ruRU", baseLocale)
