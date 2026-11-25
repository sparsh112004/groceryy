/// Local grocery catalog with common Indian household items, categories,
/// default units, Hindi/Hinglish aliases, and approximate shelf-life estimates.
///
/// Note: All `shelfLifeDays` values are only approximate suggestions for typical
/// home storage and may vary by brand, packaging, ripeness, and refrigeration.
library;

/// Supported grocery categories in Stockora.
const List<String> kCategories = [
  'Dairy',
  'Fruits',
  'Vegetables',
  'Grains & Flours',
  'Pulses',
  'Spices',
  'Snacks',
  'Beverages',
  'Bakery',
  'Oils & Condiments',
  'Frozen',
  'Other',
];

/// A catalog entry representing a common household grocery item.
class CatalogItem {
  const CatalogItem({
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.shelfLifeDays,
    this.aliases = const [],
  });

  final String name;
  final String category;

  /// One of 'pcs', 'kg', 'g', 'L', 'ml', 'packet', 'dozen'.
  final String defaultUnit;

  /// Approximate typical shelf life at home in days (suggestion only).
  final int shelfLifeDays;

  /// Lowercase search aliases including common Hindi/Hinglish names.
  final List<String> aliases;
}

/// Curated catalog of everyday Indian household grocery items.
/// Shelf-life values are only approximate suggestions.
const List<CatalogItem> kCatalog = [
  // Dairy (11)
  CatalogItem(
    name: 'Milk',
    category: 'Dairy',
    defaultUnit: 'L',
    shelfLifeDays: 3,
    aliases: ['doodh', 'dudh', 'toned milk', 'full cream milk'],
  ),
  CatalogItem(
    name: 'Curd',
    category: 'Dairy',
    defaultUnit: 'g',
    shelfLifeDays: 5,
    aliases: ['dahi', 'yogurt', 'yoghurt'],
  ),
  CatalogItem(
    name: 'Paneer',
    category: 'Dairy',
    defaultUnit: 'g',
    shelfLifeDays: 5,
    aliases: ['cottage cheese', 'malai paneer'],
  ),
  CatalogItem(
    name: 'Butter',
    category: 'Dairy',
    defaultUnit: 'g',
    shelfLifeDays: 60,
    aliases: ['makkhan', 'makhan', 'salted butter'],
  ),
  CatalogItem(
    name: 'Cheese',
    category: 'Dairy',
    defaultUnit: 'packet',
    shelfLifeDays: 60,
    aliases: ['cheese slices', 'cheese cubes', 'mozzarella', 'cheddar'],
  ),
  CatalogItem(
    name: 'Buttermilk',
    category: 'Dairy',
    defaultUnit: 'ml',
    shelfLifeDays: 4,
    aliases: ['chaach', 'chaas', 'mattha'],
  ),
  CatalogItem(
    name: 'Lassi',
    category: 'Dairy',
    defaultUnit: 'ml',
    shelfLifeDays: 5,
    aliases: ['sweet lassi', 'mango lassi'],
  ),
  CatalogItem(
    name: 'Fresh Cream',
    category: 'Dairy',
    defaultUnit: 'ml',
    shelfLifeDays: 7,
    aliases: ['malai', 'cream', 'cooking cream'],
  ),
  CatalogItem(
    name: 'Condensed Milk',
    category: 'Dairy',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['milkmaid', 'mithai mate'],
  ),
  CatalogItem(
    name: 'Milk Powder',
    category: 'Dairy',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['dairy whitener', 'doodh powder'],
  ),
  CatalogItem(
    name: 'Khoya',
    category: 'Dairy',
    defaultUnit: 'g',
    shelfLifeDays: 7,
    aliases: ['mawa', 'khoa'],
  ),

  // Fruits (12)
  CatalogItem(
    name: 'Banana',
    category: 'Fruits',
    defaultUnit: 'dozen',
    shelfLifeDays: 5,
    aliases: ['kela', 'bananas'],
  ),
  CatalogItem(
    name: 'Apple',
    category: 'Fruits',
    defaultUnit: 'kg',
    shelfLifeDays: 14,
    aliases: ['seb', 'apples'],
  ),
  CatalogItem(
    name: 'Mango',
    category: 'Fruits',
    defaultUnit: 'kg',
    shelfLifeDays: 6,
    aliases: ['aam', 'alphonso', 'kesar'],
  ),
  CatalogItem(
    name: 'Orange',
    category: 'Fruits',
    defaultUnit: 'kg',
    shelfLifeDays: 10,
    aliases: ['santra', 'kinnow', 'oranges'],
  ),
  CatalogItem(
    name: 'Pomegranate',
    category: 'Fruits',
    defaultUnit: 'kg',
    shelfLifeDays: 14,
    aliases: ['anar', 'anaar'],
  ),
  CatalogItem(
    name: 'Papaya',
    category: 'Fruits',
    defaultUnit: 'pcs',
    shelfLifeDays: 5,
    aliases: ['papita'],
  ),
  CatalogItem(
    name: 'Grapes',
    category: 'Fruits',
    defaultUnit: 'g',
    shelfLifeDays: 7,
    aliases: ['angoor', 'angur'],
  ),
  CatalogItem(
    name: 'Watermelon',
    category: 'Fruits',
    defaultUnit: 'pcs',
    shelfLifeDays: 7,
    aliases: ['tarbooz', 'tarbuj'],
  ),
  CatalogItem(
    name: 'Guava',
    category: 'Fruits',
    defaultUnit: 'kg',
    shelfLifeDays: 5,
    aliases: ['amrood', 'amrud', 'peru'],
  ),
  CatalogItem(
    name: 'Lemon',
    category: 'Fruits',
    defaultUnit: 'pcs',
    shelfLifeDays: 14,
    aliases: ['nimbu', 'neembu', 'lime'],
  ),
  CatalogItem(
    name: 'Sweet Lime',
    category: 'Fruits',
    defaultUnit: 'kg',
    shelfLifeDays: 10,
    aliases: ['mosambi', 'mausambi'],
  ),
  CatalogItem(
    name: 'Coconut',
    category: 'Fruits',
    defaultUnit: 'pcs',
    shelfLifeDays: 14,
    aliases: ['nariyal', 'narial'],
  ),

  // Vegetables (22)
  CatalogItem(
    name: 'Tomato',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 7,
    aliases: ['tamatar', 'tomatoes'],
  ),
  CatalogItem(
    name: 'Onion',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 30,
    aliases: ['pyaaz', 'pyaz', 'kanda', 'onions'],
  ),
  CatalogItem(
    name: 'Potato',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 30,
    aliases: ['aloo', 'alu', 'potatoes'],
  ),
  CatalogItem(
    name: 'Garlic',
    category: 'Vegetables',
    defaultUnit: 'g',
    shelfLifeDays: 45,
    aliases: ['lehsun', 'lahsun'],
  ),
  CatalogItem(
    name: 'Ginger',
    category: 'Vegetables',
    defaultUnit: 'g',
    shelfLifeDays: 21,
    aliases: ['adrak'],
  ),
  CatalogItem(
    name: 'Green Chilli',
    category: 'Vegetables',
    defaultUnit: 'g',
    shelfLifeDays: 10,
    aliases: ['hari mirch', 'mirchi', 'green chili'],
  ),
  CatalogItem(
    name: 'Coriander Leaves',
    category: 'Vegetables',
    defaultUnit: 'packet',
    shelfLifeDays: 5,
    aliases: ['dhaniya patta', 'hara dhaniya', 'kothimbir', 'cilantro'],
  ),
  CatalogItem(
    name: 'Spinach',
    category: 'Vegetables',
    defaultUnit: 'packet',
    shelfLifeDays: 4,
    aliases: ['palak'],
  ),
  CatalogItem(
    name: 'Cauliflower',
    category: 'Vegetables',
    defaultUnit: 'pcs',
    shelfLifeDays: 7,
    aliases: ['gobhi', 'phool gobhi', 'gobi'],
  ),
  CatalogItem(
    name: 'Cabbage',
    category: 'Vegetables',
    defaultUnit: 'pcs',
    shelfLifeDays: 10,
    aliases: ['patta gobhi', 'band gobhi'],
  ),
  CatalogItem(
    name: 'Green Peas',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 6,
    aliases: ['matar', 'hara matar', 'peas'],
  ),
  CatalogItem(
    name: 'Okra',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 5,
    aliases: ['bhindi', 'ladyfinger', 'lady finger'],
  ),
  CatalogItem(
    name: 'Brinjal',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 7,
    aliases: ['baingan', 'eggplant', 'aubergine'],
  ),
  CatalogItem(
    name: 'Carrot',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 14,
    aliases: ['gajar', 'carrots'],
  ),
  CatalogItem(
    name: 'Cucumber',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 7,
    aliases: ['kheera', 'kakdi'],
  ),
  CatalogItem(
    name: 'Capsicum',
    category: 'Vegetables',
    defaultUnit: 'g',
    shelfLifeDays: 7,
    aliases: ['shimla mirch', 'bell pepper'],
  ),
  CatalogItem(
    name: 'Bottle Gourd',
    category: 'Vegetables',
    defaultUnit: 'pcs',
    shelfLifeDays: 7,
    aliases: ['lauki', 'ghiya', 'doodhi'],
  ),
  CatalogItem(
    name: 'Bitter Gourd',
    category: 'Vegetables',
    defaultUnit: 'g',
    shelfLifeDays: 6,
    aliases: ['karela'],
  ),
  CatalogItem(
    name: 'Radish',
    category: 'Vegetables',
    defaultUnit: 'kg',
    shelfLifeDays: 10,
    aliases: ['mooli', 'muli'],
  ),
  CatalogItem(
    name: 'Beetroot',
    category: 'Vegetables',
    defaultUnit: 'g',
    shelfLifeDays: 14,
    aliases: ['chukandar'],
  ),
  CatalogItem(
    name: 'French Beans',
    category: 'Vegetables',
    defaultUnit: 'g',
    shelfLifeDays: 6,
    aliases: ['beans', 'fali', 'phali'],
  ),
  CatalogItem(
    name: 'Curry Leaves',
    category: 'Vegetables',
    defaultUnit: 'packet',
    shelfLifeDays: 7,
    aliases: ['kadi patta', 'kadhi patta', 'meetha neem'],
  ),

  // Grains & Flours (12)
  CatalogItem(
    name: 'Rice',
    category: 'Grains & Flours',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['chawal', 'chaval', 'sona masoori', 'kolam'],
  ),
  CatalogItem(
    name: 'Basmati Rice',
    category: 'Grains & Flours',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['basmati chawal', 'pulao rice', 'biryani rice'],
  ),
  CatalogItem(
    name: 'Wheat Flour',
    category: 'Grains & Flours',
    defaultUnit: 'kg',
    shelfLifeDays: 120,
    aliases: ['atta', 'aata', 'gehu ka atta', 'chakki atta'],
  ),
  CatalogItem(
    name: 'All-Purpose Flour',
    category: 'Grains & Flours',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['maida', 'refined flour'],
  ),
  CatalogItem(
    name: 'Besan',
    category: 'Grains & Flours',
    defaultUnit: 'g',
    shelfLifeDays: 150,
    aliases: ['gram flour', 'chickpea flour'],
  ),
  CatalogItem(
    name: 'Semolina',
    category: 'Grains & Flours',
    defaultUnit: 'g',
    shelfLifeDays: 150,
    aliases: ['suji', 'sooji', 'rava', 'bombay rava'],
  ),
  CatalogItem(
    name: 'Poha',
    category: 'Grains & Flours',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['flattened rice', 'chivda', 'aval'],
  ),
  CatalogItem(
    name: 'Oats',
    category: 'Grains & Flours',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['rolled oats', 'masala oats'],
  ),
  CatalogItem(
    name: 'Dalia',
    category: 'Grains & Flours',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['broken wheat', 'cracked wheat', 'lapsi'],
  ),
  CatalogItem(
    name: 'Vermicelli',
    category: 'Grains & Flours',
    defaultUnit: 'packet',
    shelfLifeDays: 270,
    aliases: ['sevai', 'seviyan', 'semiya'],
  ),
  CatalogItem(
    name: 'Rice Flour',
    category: 'Grains & Flours',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['chawal ka atta'],
  ),
  CatalogItem(
    name: 'Sabudana',
    category: 'Grains & Flours',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['sago', 'tapioca pearls'],
  ),

  // Pulses (9)
  CatalogItem(
    name: 'Toor Dal',
    category: 'Pulses',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['arhar dal', 'tuvar dal', 'pigeon peas'],
  ),
  CatalogItem(
    name: 'Moong Dal',
    category: 'Pulses',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['mung dal', 'yellow moong dal', 'green moong'],
  ),
  CatalogItem(
    name: 'Masoor Dal',
    category: 'Pulses',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['red lentils', 'malka masoor'],
  ),
  CatalogItem(
    name: 'Chana Dal',
    category: 'Pulses',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['split bengal gram'],
  ),
  CatalogItem(
    name: 'Urad Dal',
    category: 'Pulses',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['black gram', 'urad gota', 'dhuli urad'],
  ),
  CatalogItem(
    name: 'Kabuli Chana',
    category: 'Pulses',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['chole', 'chickpeas', 'white chana'],
  ),
  CatalogItem(
    name: 'Kala Chana',
    category: 'Pulses',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['black chickpeas', 'desi chana', 'chana'],
  ),
  CatalogItem(
    name: 'Rajma',
    category: 'Pulses',
    defaultUnit: 'kg',
    shelfLifeDays: 365,
    aliases: ['kidney beans', 'red rajma'],
  ),
  CatalogItem(
    name: 'Soya Chunks',
    category: 'Pulses',
    defaultUnit: 'packet',
    shelfLifeDays: 365,
    aliases: ['nutrela', 'soya badi', 'soybean chunks'],
  ),

  // Spices (15)
  CatalogItem(
    name: 'Turmeric Powder',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['haldi', 'turmeric'],
  ),
  CatalogItem(
    name: 'Red Chilli Powder',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['lal mirch', 'laal mirch', 'chilli powder', 'mirchi powder'],
  ),
  CatalogItem(
    name: 'Coriander Powder',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['dhaniya powder', 'dhania powder'],
  ),
  CatalogItem(
    name: 'Cumin Seeds',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['jeera', 'zeera'],
  ),
  CatalogItem(
    name: 'Mustard Seeds',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['rai', 'sarson'],
  ),
  CatalogItem(
    name: 'Garam Masala',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['garam masala powder'],
  ),
  CatalogItem(
    name: 'Black Pepper',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['kali mirch', 'peppercorn'],
  ),
  CatalogItem(
    name: 'Cardamom',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['elaichi', 'hari elaichi'],
  ),
  CatalogItem(
    name: 'Cloves',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['laung', 'lavang'],
  ),
  CatalogItem(
    name: 'Cinnamon',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['dalchini'],
  ),
  CatalogItem(
    name: 'Asafoetida',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['hing', 'heeng'],
  ),
  CatalogItem(
    name: 'Kasuri Methi',
    category: 'Spices',
    defaultUnit: 'packet',
    shelfLifeDays: 270,
    aliases: ['dried fenugreek leaves'],
  ),
  CatalogItem(
    name: 'Carom Seeds',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['ajwain'],
  ),
  CatalogItem(
    name: 'Fennel Seeds',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['saunf'],
  ),
  CatalogItem(
    name: 'Chaat Masala',
    category: 'Spices',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['chat masala'],
  ),

  // Snacks (12)
  CatalogItem(
    name: 'Biscuits',
    category: 'Snacks',
    defaultUnit: 'packet',
    shelfLifeDays: 120,
    aliases: ['cookies', 'parle g', 'marie', 'cream biscuits'],
  ),
  CatalogItem(
    name: 'Namkeen',
    category: 'Snacks',
    defaultUnit: 'packet',
    shelfLifeDays: 90,
    aliases: ['bhujia', 'mixture', 'sev', 'farsan'],
  ),
  CatalogItem(
    name: 'Potato Chips',
    category: 'Snacks',
    defaultUnit: 'packet',
    shelfLifeDays: 90,
    aliases: ['chips', 'wafers', 'lays'],
  ),
  CatalogItem(
    name: 'Instant Noodles',
    category: 'Snacks',
    defaultUnit: 'packet',
    shelfLifeDays: 270,
    aliases: ['noodles', 'maggi', 'hakka noodles'],
  ),
  CatalogItem(
    name: 'Pasta',
    category: 'Snacks',
    defaultUnit: 'packet',
    shelfLifeDays: 365,
    aliases: ['macaroni', 'penne', 'fusilli'],
  ),
  CatalogItem(
    name: 'Makhana',
    category: 'Snacks',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['fox nuts', 'lotus seeds'],
  ),
  CatalogItem(
    name: 'Peanuts',
    category: 'Snacks',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['moongfali', 'singdana', 'groundnuts'],
  ),
  CatalogItem(
    name: 'Almonds',
    category: 'Snacks',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['badam', 'badaam'],
  ),
  CatalogItem(
    name: 'Cashews',
    category: 'Snacks',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['kaju'],
  ),
  CatalogItem(
    name: 'Raisins',
    category: 'Snacks',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['kishmish', 'kismis'],
  ),
  CatalogItem(
    name: 'Papad',
    category: 'Snacks',
    defaultUnit: 'packet',
    shelfLifeDays: 270,
    aliases: ['papadum', 'lijjat papad'],
  ),
  CatalogItem(
    name: 'Cornflakes',
    category: 'Snacks',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['breakfast cereal', 'cereal'],
  ),

  // Beverages (7)
  CatalogItem(
    name: 'Tea Leaves',
    category: 'Beverages',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['chai patti', 'tea', 'chai'],
  ),
  CatalogItem(
    name: 'Coffee',
    category: 'Beverages',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['instant coffee', 'filter coffee'],
  ),
  CatalogItem(
    name: 'Green Tea',
    category: 'Beverages',
    defaultUnit: 'packet',
    shelfLifeDays: 365,
    aliases: ['tea bags', 'herbal tea'],
  ),
  CatalogItem(
    name: 'Packaged Juice',
    category: 'Beverages',
    defaultUnit: 'L',
    shelfLifeDays: 180,
    aliases: ['juice', 'fruit juice', 'mango juice', 'orange juice'],
  ),
  CatalogItem(
    name: 'Soft Drink',
    category: 'Beverages',
    defaultUnit: 'L',
    shelfLifeDays: 180,
    aliases: ['cold drink', 'soda', 'cola'],
  ),
  CatalogItem(
    name: 'Coconut Water',
    category: 'Beverages',
    defaultUnit: 'ml',
    shelfLifeDays: 90,
    aliases: ['nariyal pani'],
  ),
  CatalogItem(
    name: 'Health Drink',
    category: 'Beverages',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['bournvita', 'horlicks', 'complan', 'malt drink'],
  ),

  // Bakery (6)
  CatalogItem(
    name: 'Bread',
    category: 'Bakery',
    defaultUnit: 'packet',
    shelfLifeDays: 4,
    aliases: ['white bread', 'sandwich bread', 'double roti'],
  ),
  CatalogItem(
    name: 'Brown Bread',
    category: 'Bakery',
    defaultUnit: 'packet',
    shelfLifeDays: 4,
    aliases: ['whole wheat bread', 'atta bread', 'multigrain bread'],
  ),
  CatalogItem(
    name: 'Pav',
    category: 'Bakery',
    defaultUnit: 'packet',
    shelfLifeDays: 3,
    aliases: ['ladi pav', 'vada pav bun'],
  ),
  CatalogItem(
    name: 'Burger Buns',
    category: 'Bakery',
    defaultUnit: 'packet',
    shelfLifeDays: 4,
    aliases: ['buns', 'bun'],
  ),
  CatalogItem(
    name: 'Rusk',
    category: 'Bakery',
    defaultUnit: 'packet',
    shelfLifeDays: 90,
    aliases: ['toast', 'suji rusk'],
  ),
  CatalogItem(
    name: 'Pizza Base',
    category: 'Bakery',
    defaultUnit: 'packet',
    shelfLifeDays: 5,
    aliases: ['pizza crust'],
  ),

  // Oils & Condiments (14)
  CatalogItem(
    name: 'Cooking Oil',
    category: 'Oils & Condiments',
    defaultUnit: 'L',
    shelfLifeDays: 365,
    aliases: ['tel', 'refined oil', 'sunflower oil', 'groundnut oil'],
  ),
  CatalogItem(
    name: 'Mustard Oil',
    category: 'Oils & Condiments',
    defaultUnit: 'L',
    shelfLifeDays: 365,
    aliases: ['sarson ka tel', 'sarso tel'],
  ),
  CatalogItem(
    name: 'Olive Oil',
    category: 'Oils & Condiments',
    defaultUnit: 'ml',
    shelfLifeDays: 365,
    aliases: ['extra virgin olive oil'],
  ),
  CatalogItem(
    name: 'Ghee',
    category: 'Oils & Condiments',
    defaultUnit: 'ml',
    shelfLifeDays: 270,
    aliases: ['desi ghee', 'clarified butter'],
  ),
  CatalogItem(
    name: 'Sugar',
    category: 'Oils & Condiments',
    defaultUnit: 'kg',
    shelfLifeDays: 730,
    aliases: ['cheeni', 'chini', 'shakkar'],
  ),
  CatalogItem(
    name: 'Jaggery',
    category: 'Oils & Condiments',
    defaultUnit: 'kg',
    shelfLifeDays: 180,
    aliases: ['gud', 'gur'],
  ),
  CatalogItem(
    name: 'Salt',
    category: 'Oils & Condiments',
    defaultUnit: 'kg',
    shelfLifeDays: 730,
    aliases: ['namak', 'tata salt', 'iodized salt'],
  ),
  CatalogItem(
    name: 'Black Salt',
    category: 'Oils & Condiments',
    defaultUnit: 'g',
    shelfLifeDays: 730,
    aliases: ['kala namak', 'sendha namak'],
  ),
  CatalogItem(
    name: 'Tomato Ketchup',
    category: 'Oils & Condiments',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['ketchup', 'tomato sauce', 'sauce'],
  ),
  CatalogItem(
    name: 'Soy Sauce',
    category: 'Oils & Condiments',
    defaultUnit: 'ml',
    shelfLifeDays: 365,
    aliases: ['soya sauce'],
  ),
  CatalogItem(
    name: 'Vinegar',
    category: 'Oils & Condiments',
    defaultUnit: 'ml',
    shelfLifeDays: 730,
    aliases: ['sirka', 'white vinegar'],
  ),
  CatalogItem(
    name: 'Pickle',
    category: 'Oils & Condiments',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['achar', 'achaar', 'mango pickle'],
  ),
  CatalogItem(
    name: 'Honey',
    category: 'Oils & Condiments',
    defaultUnit: 'g',
    shelfLifeDays: 730,
    aliases: ['shahad', 'madhu'],
  ),
  CatalogItem(
    name: 'Fruit Jam',
    category: 'Oils & Condiments',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['jam', 'mixed fruit jam', 'kissan jam'],
  ),

  // Frozen (6)
  CatalogItem(
    name: 'Frozen Peas',
    category: 'Frozen',
    defaultUnit: 'packet',
    shelfLifeDays: 180,
    aliases: ['frozen matar', 'safal matar'],
  ),
  CatalogItem(
    name: 'Frozen Sweet Corn',
    category: 'Frozen',
    defaultUnit: 'packet',
    shelfLifeDays: 180,
    aliases: ['frozen corn', 'sweet corn'],
  ),
  CatalogItem(
    name: 'Ice Cream',
    category: 'Frozen',
    defaultUnit: 'ml',
    shelfLifeDays: 90,
    aliases: ['kulfi', 'gelato'],
  ),
  CatalogItem(
    name: 'Frozen Paratha',
    category: 'Frozen',
    defaultUnit: 'packet',
    shelfLifeDays: 180,
    aliases: ['malabar paratha', 'aloo paratha'],
  ),
  CatalogItem(
    name: 'Frozen French Fries',
    category: 'Frozen',
    defaultUnit: 'packet',
    shelfLifeDays: 180,
    aliases: ['french fries', 'fries'],
  ),
  CatalogItem(
    name: 'Frozen Veg Nuggets',
    category: 'Frozen',
    defaultUnit: 'packet',
    shelfLifeDays: 180,
    aliases: ['nuggets', 'aloo tikki', 'smiley'],
  ),

  // Other (6)
  CatalogItem(
    name: 'Eggs',
    category: 'Other',
    defaultUnit: 'dozen',
    shelfLifeDays: 21,
    aliases: ['anda', 'ande', 'egg'],
  ),
  CatalogItem(
    name: 'Tofu',
    category: 'Other',
    defaultUnit: 'g',
    shelfLifeDays: 7,
    aliases: ['soya paneer'],
  ),
  CatalogItem(
    name: 'Tamarind',
    category: 'Other',
    defaultUnit: 'g',
    shelfLifeDays: 270,
    aliases: ['imli'],
  ),
  CatalogItem(
    name: 'Baking Powder',
    category: 'Other',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['baking soda', 'meetha soda'],
  ),
  CatalogItem(
    name: 'Custard Powder',
    category: 'Other',
    defaultUnit: 'g',
    shelfLifeDays: 365,
    aliases: ['vanilla custard'],
  ),
  CatalogItem(
    name: 'Dry Coconut',
    category: 'Other',
    defaultUnit: 'g',
    shelfLifeDays: 180,
    aliases: ['khopra', 'gola', 'nariyal burada'],
  ),
];

/// Searches [kCatalog] case-insensitively with trimmed input.
///
/// Items whose name or any alias starts with [query] are ranked before items
/// that merely contain [query]. Returns an empty list for an empty query.
List<CatalogItem> searchCatalog(String query, {int limit = 8}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty || limit <= 0) {
    return const [];
  }

  final startsWithMatches = <CatalogItem>[];
  final containsMatches = <CatalogItem>[];

  for (final item in kCatalog) {
    final lowerName = item.name.toLowerCase();
    final nameStarts = lowerName.startsWith(q);
    final aliasStarts = item.aliases.any((alias) => alias.startsWith(q));

    if (nameStarts || aliasStarts) {
      startsWithMatches.add(item);
      continue;
    }

    final nameContains = lowerName.contains(q);
    final aliasContains = item.aliases.any((alias) => alias.contains(q));

    if (nameContains || aliasContains) {
      containsMatches.add(item);
    }
  }

  return [
    ...startsWithMatches,
    ...containsMatches,
  ].take(limit).toList(growable: false);
}

/// Returns the best matching [CatalogItem] for a free-text item [name],
/// prioritizing exact name or alias matches first, then partial matches,
/// or `null` if no match is found.
CatalogItem? matchCatalogItem(String name) {
  final q = name.trim().toLowerCase();
  if (q.isEmpty) {
    return null;
  }

  // 1. Exact name match
  for (final item in kCatalog) {
    if (item.name.toLowerCase() == q) {
      return item;
    }
  }

  // 2. Exact alias match
  for (final item in kCatalog) {
    if (item.aliases.any((alias) => alias == q)) {
      return item;
    }
  }

  // 3. Name or alias starts with query
  for (final item in kCatalog) {
    if (item.name.toLowerCase().startsWith(q) ||
        item.aliases.any((alias) => alias.startsWith(q))) {
      return item;
    }
  }

  // 4. Name or alias contains query
  for (final item in kCatalog) {
    if (item.name.toLowerCase().contains(q) ||
        item.aliases.any((alias) => alias.contains(q))) {
      return item;
    }
  }

  // 5. Free-text query contains a catalog item's name or alias (longest match)
  CatalogItem? bestPhraseMatch;
  var bestLength = 0;
  for (final item in kCatalog) {
    final lowerName = item.name.toLowerCase();
    if (q.contains(lowerName) && lowerName.length > bestLength) {
      bestPhraseMatch = item;
      bestLength = lowerName.length;
    }
    for (final alias in item.aliases) {
      if (q.contains(alias) && alias.length > bestLength) {
        bestPhraseMatch = item;
        bestLength = alias.length;
      }
    }
  }

  return bestPhraseMatch;
}

/// Returns the matched category for [name], or `'Other'` if no match is found.
String categoryFor(String name) {
  return matchCatalogItem(name)?.category ?? 'Other';
}

/// Returns an approximate suggested expiry [DateTime] by adding
/// `item.shelfLifeDays` to [from].
DateTime suggestedExpiry(CatalogItem item, DateTime from) {
  return from.add(Duration(days: item.shelfLifeDays));
}
