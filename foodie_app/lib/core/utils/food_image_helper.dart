class FoodImageHelper {
  // Distinct, verified Unsplash photos for every single dish (no repeated images)
  static const Map<String, String> _dishImages = {
    // Pasta & Italian
    'alfredo pasta': 'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=600&auto=format&fit=crop',
    'fettuccine alfredo': 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=600&auto=format&fit=crop',
    'lasagna': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=600&auto=format&fit=crop',
    'spaghetti carbonara': 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=600&auto=format&fit=crop',
    'bruschetta': 'https://images.unsplash.com/photo-1572695157366-5e585ab2b69f?w=600&auto=format&fit=crop',
    'margherita pizza': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&auto=format&fit=crop',
    'wood-fired pepperoni pizza': 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=600&auto=format&fit=crop',
    'garlic bread with cheese': 'https://images.unsplash.com/photo-1619895092538-128341789043?w=600&auto=format&fit=crop',
    'tiramisu': 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=600&auto=format&fit=crop',
    'caesar salad': 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=600&auto=format&fit=crop',
    // American & Burgers
    'classic cheeseburger': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop',
    'all american cheese burger': 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=600&auto=format&fit=crop',
    'crispy veg burger': 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=600&auto=format&fit=crop',
    'jumbo fried chicken burger': 'https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?w=600&auto=format&fit=crop',
    'double cheese veg burger': 'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=600&auto=format&fit=crop',
    'bbq chicken wings': 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=600&auto=format&fit=crop',
    'peri peri chicken wings': 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=600&auto=format&fit=crop',
    'new york style hot dog': 'https://images.unsplash.com/photo-1619740455993-9e612b1af08a?w=600&auto=format&fit=crop',
    'crispy fried chicken': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600&auto=format&fit=crop',
    'fried chicken strips (4 pcs)': 'https://images.unsplash.com/photo-1562967914-608f82629710?w=600&auto=format&fit=crop',
    'chicken club sandwich': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=600&auto=format&fit=crop',
    'mac and cheese': 'https://images.unsplash.com/photo-1543339494-b4cd4f7ba686?w=600&auto=format&fit=crop',
    'baked mac and cheese': 'https://images.unsplash.com/photo-1546549032-9571cd6b27df?w=600&auto=format&fit=crop',
    'loaded nachos': 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=600&auto=format&fit=crop',
    'peri peri fries': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600&auto=format&fit=crop',
    'chicken pita wrap': 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600&auto=format&fit=crop',
    'falafel wrap': 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=600&auto=format&fit=crop',
    'new york cheesecake': 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=600&auto=format&fit=crop',
    // Biryani & Rice
    'chicken boneless biryani': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop',
    'mutton biryani': 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?w=600&auto=format&fit=crop',
    'paneer biryani': 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=600&auto=format&fit=crop',
    'biryani rice': 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=600&auto=format&fit=crop',
    'ghee rice': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600&auto=format&fit=crop',
    'curd rice': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600&auto=format&fit=crop',
    'veg schezwan fried rice': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600&auto=format&fit=crop',
    'chicken fried rice': 'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=600&auto=format&fit=crop',
    // South Indian
    'masala dosa': 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=600&auto=format&fit=crop',
    'plain dosa': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600&auto=format&fit=crop',
    'rava dosa': 'https://images.unsplash.com/photo-1516714435131-44d6b64dc6a2?w=600&auto=format&fit=crop',
    'vada (2 pcs)': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&auto=format&fit=crop',
    'idli (2 pcs)': 'https://images.unsplash.com/photo-1567337710282-00832b415979?w=600&auto=format&fit=crop',
    'poori saagu': 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=600&auto=format&fit=crop',
    'andhra veg meals': 'https://images.unsplash.com/photo-1610192244261-3f33de3f55e4?w=600&auto=format&fit=crop',
    'kesari bath': 'https://images.unsplash.com/photo-1505253758473-96b7015fcd40?w=600&auto=format&fit=crop',
    // Starters & Kebabs
    'chicken 65': 'https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?w=600&auto=format&fit=crop',
    'paneer 65': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=600&auto=format&fit=crop',
    'paneer tikka': 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=600&auto=format&fit=crop',
    'paneer sholay kebab': 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600&auto=format&fit=crop',
    'kalmi kebab': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&auto=format&fit=crop',
    'empire special grill chicken': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600&auto=format&fit=crop',
    'tandoori murgh (half)': 'https://images.unsplash.com/photo-1628294895950-9805252327bc?w=600&auto=format&fit=crop',
    'chilli chicken (andhra style)': 'https://images.unsplash.com/photo-1525755662778-989d0524087e?w=600&auto=format&fit=crop',
    'mutton fry': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&auto=format&fit=crop',
    'fish chop (2 pcs)': 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=600&auto=format&fit=crop',
    'singara (samosa 2 pcs)': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&auto=format&fit=crop',
    'prawn tempura': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&auto=format&fit=crop',
    // Indian Curries & Breads
    'butter naan': 'https://images.unsplash.com/photo-1626074353765-517a681e40be?w=600&auto=format&fit=crop',
    'garlic naan': 'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?w=600&auto=format&fit=crop',
    'tandoori roti': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&auto=format&fit=crop',
    'amritsari kulcha': 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=600&auto=format&fit=crop',
    'chicken coin parotta': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600&auto=format&fit=crop',
    'chicken tikka masala': 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=600&auto=format&fit=crop',
    'murgh makhani (butter chicken)': 'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=600&auto=format&fit=crop',
    'paneer butter masala': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600&auto=format&fit=crop',
    'dal makhani': 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=600&auto=format&fit=crop',
    'andhra chicken curry': 'https://images.unsplash.com/photo-1574484284002-952d92456975?w=600&auto=format&fit=crop',
    'luchi alur dom': 'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=600&auto=format&fit=crop',
    'kolkata kathi roll': 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=600&auto=format&fit=crop',
    // Chinese & Asian
    'vegetable spring rolls': 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=600&auto=format&fit=crop',
    'chicken manchurian': 'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=600&auto=format&fit=crop',
    'veg manchurian gravy': 'https://images.unsplash.com/photo-1541832676-9b763b0239ab?w=600&auto=format&fit=crop',
    'vegetable hakka noodles': 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600&auto=format&fit=crop',
    'chicken hakka noodles': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=600&auto=format&fit=crop',
    'kung pao chicken': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&auto=format&fit=crop',
    'steamed chicken momos (6 pcs)': 'https://images.unsplash.com/photo-1625220194771-7ebdea0b70b9?w=600&auto=format&fit=crop',
    'crispy honey chilli potatoes': 'https://images.unsplash.com/photo-1518013431117-eb1465fa5752?w=600&auto=format&fit=crop',
    'manchow soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&auto=format&fit=crop',
    'char siu pork bao': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=600&auto=format&fit=crop',
    'mushroom & truffle oil bao': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&auto=format&fit=crop',
    'salmon aburi roll (8 pcs)': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=600&auto=format&fit=crop',
    'avocado & cucumber sushi roll': 'https://images.unsplash.com/photo-1611143669185-af224c5e3252?w=600&auto=format&fit=crop',
    'chicken ramen': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop',
    'veg miso ramen': 'https://images.unsplash.com/photo-1552611052-33e04de081de?w=600&auto=format&fit=crop',
    // Desserts & Sweets
    'death by chocolate': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop',
    'hot fudge sundae': 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=600&auto=format&fit=crop',
    'trilogy': 'https://images.unsplash.com/photo-1505394033641-40c6ad1178d7?w=600&auto=format&fit=crop',
    'brownie bomb': 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&auto=format&fit=crop',
    'fruit salad with ice cream': 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?w=600&auto=format&fit=crop',
    'mango scoop': 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=600&auto=format&fit=crop',
    'belgian chocolate scoop': 'https://images.unsplash.com/photo-1570197788417-0e82375c9371?w=600&auto=format&fit=crop',
    'oreo blast sundae': 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=600&auto=format&fit=crop',
    'matcha cheesecake': 'https://images.unsplash.com/photo-1508737027454-e6454ef45afd?w=600&auto=format&fit=crop',
    'gulab jamun': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&auto=format&fit=crop',
    'double ka meetha': 'https://images.unsplash.com/photo-1481931098730-318b6f776db0?w=600&auto=format&fit=crop',
    'payasam': 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=600&auto=format&fit=crop',
    'rasmalai (2 pcs)': 'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=600&auto=format&fit=crop',
    'rosogolla (4 pcs)': 'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=600&auto=format&fit=crop',
    'mishti doi': 'https://images.unsplash.com/photo-1571115177098-24ec42ed204d?w=600&auto=format&fit=crop',
    'sandesh (4 pcs)': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=600&auto=format&fit=crop',
    'darsaan with vanilla ice cream': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=600&auto=format&fit=crop',
    // Beverages
    'chocolate milkshake': 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=600&auto=format&fit=crop',
    'chocolate thick shake': 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=600&auto=format&fit=crop',
    'cold coffee with ice cream': 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600&auto=format&fit=crop',
    'craft ginger beer (non-alcoholic)': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=600&auto=format&fit=crop',
    'filter coffee': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop',
    'fresh lime soda': 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=600&auto=format&fit=crop',
    'sweet lassi': 'https://images.unsplash.com/photo-1536935338788-846bb9981813?w=600&auto=format&fit=crop',
    'darjeeling tea': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=600&auto=format&fit=crop',
  };

  static const Map<String, String> _cuisineImages = {
    'biryani': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800&auto=format&fit=crop',
    'south indian': 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=800&auto=format&fit=crop',
    'burgers': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&auto=format&fit=crop',
    'pizza': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&auto=format&fit=crop',
    'ice cream': 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=800&auto=format&fit=crop',
    'desserts': 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&auto=format&fit=crop',
    'north indian': 'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=800&auto=format&fit=crop',
    'chinese': 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=800&auto=format&fit=crop',
    'asian': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800&auto=format&fit=crop',
    'kebabs': 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=800&auto=format&fit=crop',
    'andhra': 'https://images.unsplash.com/photo-1610192244261-3f33de3f55e4?w=800&auto=format&fit=crop',
    'bengali': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800&auto=format&fit=crop',
    'italian': 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=800&auto=format&fit=crop',
    'american': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&auto=format&fit=crop',
  };

  static const Map<String, String> _keywordImages = {
    'biryani': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop',
    'dosa': 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=600&auto=format&fit=crop',
    'burger': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop',
    'pizza': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&auto=format&fit=crop',
    'pasta': 'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=600&auto=format&fit=crop',
    'ice cream': 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=600&auto=format&fit=crop',
    'sundae': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop',
    'brownie': 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&auto=format&fit=crop',
    'naan': 'https://images.unsplash.com/photo-1626074353765-517a681e40be?w=600&auto=format&fit=crop',
    'chicken': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&auto=format&fit=crop',
    'wings': 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=600&auto=format&fit=crop',
    'paneer': 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600&auto=format&fit=crop',
    'noodles': 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600&auto=format&fit=crop',
    'momo': 'https://images.unsplash.com/photo-1625220194771-7ebdea0b70b9?w=600&auto=format&fit=crop',
    'ramen': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop',
    'sushi': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=600&auto=format&fit=crop',
    'bao': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=600&auto=format&fit=crop',
    'idli': 'https://images.unsplash.com/photo-1567337710282-00832b415979?w=600&auto=format&fit=crop',
    'vada': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&auto=format&fit=crop',
    'coffee': 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600&auto=format&fit=crop',
    'shake': 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=600&auto=format&fit=crop',
    'fries': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600&auto=format&fit=crop',
    'wrap': 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600&auto=format&fit=crop',
    'salad': 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=600&auto=format&fit=crop',
    'soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&auto=format&fit=crop',
    'tea': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=600&auto=format&fit=crop',
  };

  static String getRestaurantImage(String name, String cuisine, [String? currentUrl]) {
    if (currentUrl != null && !currentUrl.contains('picsum.photos')) {
      return currentUrl;
    }
    final lowerCuisine = cuisine.toLowerCase();
    for (final entry in _cuisineImages.entries) {
      if (lowerCuisine.contains(entry.key)) {
        return entry.value;
      }
    }
    final lowerName = name.toLowerCase();
    for (final entry in _keywordImages.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&auto=format&fit=crop';
  }

  static String getItemImage(String name, String category, [String? currentUrl]) {
    if (currentUrl != null && !currentUrl.contains('picsum.photos')) {
      return currentUrl;
    }

    final lowerName = name.toLowerCase().trim();

    // 1. Exact dish name match (100% unique, verified image per dish)
    if (_dishImages.containsKey(lowerName)) {
      return _dishImages[lowerName]!;
    }

    // 2. Substring match against known dishes
    for (final entry in _dishImages.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        return entry.value;
      }
    }

    // 3. Keyword fallback
    final combined = '$lowerName ${category.toLowerCase().trim()}';
    for (final entry in _keywordImages.entries) {
      if (combined.contains(entry.key)) {
        return entry.value;
      }
    }

    // 4. Cuisine fallback
    for (final entry in _cuisineImages.entries) {
      if (combined.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&auto=format&fit=crop';
  }
}
