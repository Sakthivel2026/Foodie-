require('dotenv').config();
const pool = require('../config/db');

const sampleRestaurants = [
  {
    name: 'Meghana Foods',
    cuisine: 'Biryani, North Indian',
    rating: 4.6,
    delivery_time_min: 25,
    delivery_fee_paise: 3500,
    lat: 12.9345,
    lng: 77.6242,
    is_open: true,
    slug: 'meghana-foods',
    items: [
      { name: 'Chicken Boneless Biryani', description: 'Spicy and flavorful chicken biryani with special spices', price_paise: 34000, is_veg: false, category: 'Biryani' },
      { name: 'Mutton Biryani', description: 'Tender mutton cooked with basmati rice', price_paise: 42000, is_veg: false, category: 'Biryani' },
      { name: 'Paneer Biryani', description: 'Fragrant biryani layered with marinated cottage cheese', price_paise: 28000, is_veg: true, category: 'Biryani' },
      { name: 'Chicken 65', description: 'Deep fried spicy chicken bites', price_paise: 29000, is_veg: false, category: 'Starters' },
      { name: 'Paneer 65', description: 'Crispy fried paneer cubes with curry leaves', price_paise: 25000, is_veg: true, category: 'Starters' },
      { name: 'Butter Naan', description: 'Soft Indian bread glazed with butter', price_paise: 6000, is_veg: true, category: 'Breads' },
      { name: 'Gulab Jamun', description: 'Sweet milk solid dumplings in sugar syrup', price_paise: 9000, is_veg: true, category: 'Desserts' },
      { name: 'Double Ka Meetha', description: 'Traditional Hyderabadi bread pudding', price_paise: 12000, is_veg: true, category: 'Desserts' },
    ]
  },
  {
    name: 'Corner House Ice Creams',
    cuisine: 'Desserts, Ice Cream',
    rating: 4.8,
    delivery_time_min: 20,
    delivery_fee_paise: 2500,
    lat: 12.9716,
    lng: 77.5946,
    is_open: true,
    slug: 'corner-house',
    items: [
      { name: 'Death By Chocolate', description: 'Iconic chocolate sundae with nuts and cherries', price_paise: 26000, is_veg: true, category: 'Sundaes' },
      { name: 'Hot Fudge Sundae', description: 'Vanilla ice cream drizzled with rich hot chocolate fudge', price_paise: 19000, is_veg: true, category: 'Sundaes' },
      { name: 'Trilogy', description: 'Combination of chocolate, butterscotch, and vanilla ice creams', price_paise: 22000, is_veg: true, category: 'Sundaes' },
      { name: 'Brownie Bomb', description: 'Warm brownie served with vanilla ice cream', price_paise: 21000, is_veg: true, category: 'Desserts' },
      { name: 'Fruit Salad with Ice Cream', description: 'Fresh seasonal fruits topped with vanilla ice cream', price_paise: 18000, is_veg: true, category: 'Desserts' },
      { name: 'Chocolate Thick Shake', description: 'Creamy rich chocolate milk shake', price_paise: 16000, is_veg: true, category: 'Beverages' },
      { name: 'Mango Scoop', description: 'Single scoop of seasonal mango ice cream', price_paise: 8000, is_veg: true, category: 'Scoops' },
      { name: 'Belgian Chocolate Scoop', description: 'Premium dark Belgian chocolate scoop', price_paise: 9500, is_veg: true, category: 'Scoops' },
    ]
  },
  {
    name: 'Truffles',
    cuisine: 'American, Burgers, Cafe',
    rating: 4.5,
    delivery_time_min: 30,
    delivery_fee_paise: 4000,
    lat: 12.9352,
    lng: 77.6145,
    is_open: true,
    slug: 'truffles',
    items: [
      { name: 'Classic Cheeseburger', description: 'Juicy grilled beef patty loaded with melted cheddar cheese, fresh lettuce, pickles, and secret burger sauce', price_paise: 29900, is_veg: false, category: 'American' },
      { name: 'BBQ Chicken Wings', description: 'Crispy fried wings tossed in rich, smoky sweet barbecue sauce', price_paise: 28900, is_veg: false, category: 'American' },
      { name: 'New York Style Hot Dog', description: 'Grilled all-beef frankfurter in a soft bun with sauerkraut, spicy deli mustard, and relish', price_paise: 22900, is_veg: false, category: 'American' },
      { name: 'Crispy Fried Chicken', description: 'Golden-fried seasoned chicken pieces with a crunchy spiced batter, served with ranch dip', price_paise: 34900, is_veg: false, category: 'American' },
      { name: 'Mac and Cheese', description: 'Tender elbow macaroni baked in a velvety three-cheese cheddar blend with golden breadcrumb crust', price_paise: 26900, is_veg: true, category: 'American' },
      { name: 'Loaded Nachos', description: 'Tortilla chips with melted cheese and jalapeños', price_paise: 23000, is_veg: true, category: 'Starters' },
      { name: 'Cold Coffee with Ice Cream', description: 'Blended cold coffee topped with vanilla scoop', price_paise: 17000, is_veg: true, category: 'Beverages' },
      { name: 'New York Cheesecake', description: 'Classic creamy baked cheesecake slice', price_paise: 22000, is_veg: true, category: 'Desserts' },
    ]
  },
  {
    name: 'Vidyarthi Bhavan',
    cuisine: 'South Indian',
    rating: 4.7,
    delivery_time_min: 25,
    delivery_fee_paise: 3000,
    lat: 12.9410,
    lng: 77.5738,
    is_open: true,
    slug: 'vidyarthi-bhavan',
    items: [
      { name: 'Masala Dosa', description: 'Crispy golden dosa stuffed with potato masala and butter', price_paise: 9000, is_veg: true, category: 'Dosas' },
      { name: 'Plain Dosa', description: 'Classic crispy South Indian crepe served with chutney and sambar', price_paise: 7500, is_veg: true, category: 'Dosas' },
      { name: 'Rava Dosa', description: 'Crispy semolina dosa flavored with cumin and green chilies', price_paise: 9500, is_veg: true, category: 'Dosas' },
      { name: 'Vada (2 pcs)', description: 'Crispy lentil fritters served with coconut chutney', price_paise: 6000, is_veg: true, category: 'Snacks' },
      { name: 'Idli (2 pcs)', description: 'Steamed rice cakes served with sambar and fresh chutney', price_paise: 5000, is_veg: true, category: 'Snacks' },
      { name: 'Poori Saagu', description: 'Fluffy fried pooris served with spiced potato saagu', price_paise: 8500, is_veg: true, category: 'Breakfast' },
      { name: 'Kesari Bath', description: 'Sweet semolina dessert cooked with ghee and saffron', price_paise: 6500, is_veg: true, category: 'Sweets' },
      { name: 'Filter Coffee', description: 'Authentic South Indian brass filter coffee', price_paise: 3500, is_veg: true, category: 'Beverages' },
    ]
  },
  {
    name: 'Empire Restaurant',
    cuisine: 'North Indian, Kebabs, Mughlai',
    rating: 4.3,
    delivery_time_min: 35,
    delivery_fee_paise: 4500,
    lat: 12.9290,
    lng: 77.6270,
    is_open: true,
    slug: 'empire-restaurant',
    items: [
      { name: 'Empire Special Grill Chicken', description: 'Charcoal grilled chicken marinated in aromatic spices', price_paise: 36000, is_veg: false, category: 'Kebabs' },
      { name: 'Chicken Tikka Masala', description: 'Tender chicken tikka in rich tomato gravy', price_paise: 33000, is_veg: false, category: 'Main Course' },
      { name: 'Paneer Butter Masala', description: 'Soft cottage cheese cubes in rich creamy gravy', price_paise: 29000, is_veg: true, category: 'Main Course' },
      { name: 'Ghee Rice', description: 'Fragrant basmati rice cooked with pure ghee and cashews', price_paise: 18000, is_veg: true, category: 'Rice' },
      { name: 'Chicken Coin Parotta', description: 'Flaky mini parottas served with spicy chicken curry', price_paise: 24000, is_veg: false, category: 'Breads' },
      { name: 'Tandoori Roti', description: 'Clay oven baked Indian bread', price_paise: 3500, is_veg: true, category: 'Breads' },
      { name: 'Kalmi Kebab', description: 'Marinated chicken drumsticks roasted in tandoor', price_paise: 31000, is_veg: false, category: 'Kebabs' },
      { name: 'Fresh Lime Soda', description: 'Refreshing lime drink sweet or salted', price_paise: 6000, is_veg: true, category: 'Beverages' },
    ]
  },
  {
    name: 'Toit Craft Brewery & Kitchen',
    cuisine: 'Italian, Pizza, Continental',
    rating: 4.6,
    delivery_time_min: 40,
    delivery_fee_paise: 5000,
    lat: 12.9791,
    lng: 77.6407,
    is_open: true,
    slug: 'toit-kitchen',
    items: [
      { name: 'Margherita Pizza', description: 'Classic mozzarella, fresh basil, and San Marzano tomato sauce pizza', price_paise: 39900, is_veg: true, category: 'Italian' },
      { name: 'Spaghetti Carbonara', description: 'Classic Roman pasta tossed with egg yolk, pecorino cheese, and crispy bacon', price_paise: 44900, is_veg: false, category: 'Italian' },
      { name: 'Lasagna', description: 'Oven-baked layered pasta sheets with rich bolognese meat sauce, béchamel, and parmesan', price_paise: 49900, is_veg: false, category: 'Italian' },
      { name: 'Fettuccine Alfredo', description: 'Ribbon pasta coated in rich creamy butter, garlic, and aged parmesan cheese sauce', price_paise: 41900, is_veg: true, category: 'Italian' },
      { name: 'Bruschetta', description: 'Grilled rustic bread rubbed with garlic, topped with diced ripe tomatoes, fresh basil, and olive oil', price_paise: 24900, is_veg: true, category: 'Italian' },
      { name: 'Garlic Bread with Cheese', description: 'Toasted baguette with herb garlic butter and mozzarella', price_paise: 21000, is_veg: true, category: 'Starters' },
      { name: 'Tiramisu', description: 'Classic Italian espresso coffee dessert', price_paise: 27000, is_veg: true, category: 'Desserts' },
      { name: 'Craft Ginger Beer (Non-Alcoholic)', description: 'House brewed spicy ginger drink', price_paise: 15000, is_veg: true, category: 'Beverages' },
    ]
  },
  {
    name: 'Nagarjuna',
    cuisine: 'Andhra, South Indian',
    rating: 4.5,
    delivery_time_min: 30,
    delivery_fee_paise: 3500,
    lat: 12.9723,
    lng: 77.6081,
    is_open: true,
    slug: 'nagarjuna',
    items: [
      { name: 'Andhra Veg Meals', description: 'Traditional banana leaf spread with rice, dal, sambar, rasam and podi', price_paise: 26000, is_veg: true, category: 'Meals' },
      { name: 'Andhra Chicken Curry', description: 'Fiery traditional Andhra style spicy chicken curry', price_paise: 33000, is_veg: false, category: 'Main Course' },
      { name: 'Chilli Chicken (Andhra Style)', description: 'Green chilli stir-fried spicy chicken bites', price_paise: 31000, is_veg: false, category: 'Starters' },
      { name: 'Mutton Fry', description: 'Dry mutton roast with black pepper and spices', price_paise: 41000, is_veg: false, category: 'Starters' },
      { name: 'Paneer Sholay Kebab', description: 'Spicy marinated paneer fried to perfection', price_paise: 27000, is_veg: true, category: 'Starters' },
      { name: 'Biryani Rice', description: 'Aromatic basmati rice cooked in biryani spices', price_paise: 16000, is_veg: true, category: 'Rice' },
      { name: 'Curd Rice', description: 'Soothing tempered curd rice with mustard seeds and curry leaves', price_paise: 13000, is_veg: true, category: 'Rice' },
      { name: 'Payasam', description: 'Traditional South Indian sweet pudding', price_paise: 9000, is_veg: true, category: 'Desserts' },
    ]
  },
  {
    name: 'Beijing Bites',
    cuisine: 'Chinese, Asian',
    rating: 4.2,
    delivery_time_min: 30,
    delivery_fee_paise: 3500,
    lat: 12.9380,
    lng: 77.6200,
    is_open: true,
    slug: 'beijing-bites',
    items: [
      { name: 'Vegetable Spring Rolls', description: 'Crisp fried rolls packed with shredded cabbage, carrots, bell peppers, and scallions with sweet chili dip', price_paise: 19900, is_veg: true, category: 'Chinese' },
      { name: 'Chicken Fried Rice', description: 'Wok-tossed fragrant jasmine rice with juicy chicken bites, scrambled eggs, and fresh scallions', price_paise: 25900, is_veg: false, category: 'Chinese' },
      { name: 'Chicken Manchurian', description: 'Succulent chicken dumplings simmered in savory Indo-Chinese dark soy, garlic, and coriander gravy', price_paise: 28900, is_veg: false, category: 'Chinese' },
      { name: 'Vegetable Hakka Noodles', description: 'Traditional wok-tossed noodles with colorful julienned veggies, white pepper, and soy sauce', price_paise: 21900, is_veg: true, category: 'Chinese' },
      { name: 'Kung Pao Chicken', description: 'Sichuan stir-fried chicken with crunchy roasted peanuts, chili peppers, and tangy scallion sauce', price_paise: 32900, is_veg: false, category: 'Chinese' },
      { name: 'Steamed Chicken Momos (6 pcs)', description: 'Juicy chicken steamed dumplings served with spicy dip', price_paise: 19000, is_veg: false, category: 'Dim Sum' },
      { name: 'Crispy Honey Chilli Potatoes', description: 'Fried potato fingers tossed in honey chilli glaze', price_paise: 20000, is_veg: true, category: 'Starters' },
      { name: 'Manchow Soup', description: 'Thick spicy vegetable soup topped with fried noodles', price_paise: 14000, is_veg: true, category: 'Soups' },
      { name: 'Darsaan with Vanilla Ice Cream', description: 'Honey crispy noodles served with ice cream', price_paise: 17000, is_veg: true, category: 'Desserts' },
    ]
  },
  {
    name: 'Punjab Grill',
    cuisine: 'North Indian, Punjabi',
    rating: 4.7,
    delivery_time_min: 40,
    delivery_fee_paise: 5000,
    lat: 12.9719,
    lng: 77.6412,
    is_open: true,
    slug: 'punjab-grill',
    items: [
      { name: 'Dal Makhani', description: 'Black lentils slow cooked overnight with butter and cream', price_paise: 34000, is_veg: true, category: 'Main Course' },
      { name: 'Murgh Makhani (Butter Chicken)', description: 'Tandoori chicken simmered in rich tomato butter gravy', price_paise: 42000, is_veg: false, category: 'Main Course' },
      { name: 'Amritsari Kulcha', description: 'Stuffed spiced potato bread served with chole', price_paise: 22000, is_veg: true, category: 'Breads' },
      { name: 'Paneer Tikka', description: 'Cottage cheese marinated in yogurt and yellow spices', price_paise: 31000, is_veg: true, category: 'Kebabs' },
      { name: 'Tandoori Murgh (Half)', description: 'Classic tandoor roasted whole chicken leg and breast', price_paise: 38000, is_veg: false, category: 'Kebabs' },
      { name: 'Garlic Naan', description: 'Leavened bread topped with minced garlic and butter', price_paise: 8000, is_veg: true, category: 'Breads' },
      { name: 'Rasmalai (2 pcs)', description: 'Soft cottage cheese discs soaked in saffron milk', price_paise: 16000, is_veg: true, category: 'Desserts' },
      { name: 'Sweet Lassi', description: 'Thick churned Punjabi yogurt drink', price_paise: 11000, is_veg: true, category: 'Beverages' },
    ]
  },
  {
    name: 'The Fatty Bao',
    cuisine: 'Asian, Japanese, Sushi',
    rating: 4.6,
    delivery_time_min: 45,
    delivery_fee_paise: 5500,
    lat: 12.9784,
    lng: 77.6430,
    is_open: true,
    slug: 'fatty-bao',
    items: [
      { name: 'Char Siu Pork Bao', description: 'Steamed open bun with barbecued pork belly', price_paise: 39000, is_veg: false, category: 'Baos' },
      { name: 'Mushroom & Truffle Oil Bao', description: 'Fluffy bao filled with wild mushrooms and truffle oil', price_paise: 34000, is_veg: true, category: 'Baos' },
      { name: 'Salmon Aburi Roll (8 pcs)', description: 'Seared salmon sushi roll with teriyaki glaze', price_paise: 58000, is_veg: false, category: 'Sushi' },
      { name: 'Avocado & Cucumber Sushi Roll', description: 'Fresh avocado and cucumber sushi with toasted sesame', price_paise: 42000, is_veg: true, category: 'Sushi' },
      { name: 'Chicken Ramen', description: 'Rich broth with ramen noodles, chicken chashu, and ajitama egg', price_paise: 45000, is_veg: false, category: 'Ramen' },
      { name: 'Veg Miso Ramen', description: 'Miso based soup with chewy noodles, tofu, and bamboo shoots', price_paise: 39000, is_veg: true, category: 'Ramen' },
      { name: 'Prawn Tempura', description: 'Crispy batter fried tiger prawns with dip', price_paise: 48000, is_veg: false, category: 'Starters' },
      { name: 'Matcha Cheesecake', description: 'Japanese green tea flavored cream cheese dessert', price_paise: 29000, is_veg: true, category: 'Desserts' },
    ]
  },
  {
    name: 'Leon Grill',
    cuisine: 'Burgers, Fast Food, Wraps',
    rating: 4.3,
    delivery_time_min: 25,
    delivery_fee_paise: 3000,
    lat: 12.9260,
    lng: 77.6780,
    is_open: true,
    slug: 'leon-grill',
    items: [
      { name: 'Jumbo Fried Chicken Burger', description: 'Crispy fried chicken breast fillet in sesame bun', price_paise: 24000, is_veg: false, category: 'Burgers' },
      { name: 'Double Cheese Veg Burger', description: 'Dual veg patties topped with melted cheese slices', price_paise: 18000, is_veg: true, category: 'Burgers' },
      { name: 'Chicken Pita Wrap', description: 'Grilled chicken wrapped in soft pita bread with garlic sauce', price_paise: 21000, is_veg: false, category: 'Wraps' },
      { name: 'Falafel Wrap', description: 'Crispy chickpea falafels with hummus in pita bread', price_paise: 17000, is_veg: true, category: 'Wraps' },
      { name: 'Peri Peri Fries', description: 'Crispy potato fries dusted with peri peri seasoning', price_paise: 11000, is_veg: true, category: 'Sides' },
      { name: 'Fried Chicken Strips (4 pcs)', description: 'Boneless tender chicken strips served with dip', price_paise: 22000, is_veg: false, category: 'Sides' },
      { name: 'Chocolate Milkshake', description: 'Chilled creamy chocolate drink', price_paise: 13000, is_veg: true, category: 'Beverages' },
      { name: 'Oreo Blast Sundae', description: 'Crushed Oreo cookies with vanilla ice cream and hot chocolate', price_paise: 15000, is_veg: true, category: 'Desserts' },
    ]
  },
  {
    name: 'Sabyasachi Sweet & Savory',
    cuisine: 'Bengali, Sweets, Snacks',
    rating: 4.4,
    delivery_time_min: 20,
    delivery_fee_paise: 2500,
    lat: 12.9295,
    lng: 77.5810,
    is_open: false, // One closed restaurant to test is_open logic!
    slug: 'sabyasachi-sweets',
    items: [
      { name: 'Kolkata Kathi Roll', description: 'Egg and chicken wrapped in crispy paratha', price_paise: 14000, is_veg: false, category: 'Snacks' },
      { name: 'Luchi Alur Dom', description: 'Deep fried puffed bread served with spicy potato curry', price_paise: 12000, is_veg: true, category: 'Snacks' },
      { name: 'Rosogolla (4 pcs)', description: 'Classic Bengali spongy cottage cheese balls in sugar syrup', price_paise: 10000, is_veg: true, category: 'Sweets' },
      { name: 'Mishti Doi', description: 'Traditional sweetened fermented Bengali yogurt', price_paise: 9000, is_veg: true, category: 'Sweets' },
      { name: 'Sandesh (4 pcs)', description: 'Traditional chhena sweet flavored with cardamom', price_paise: 11000, is_veg: true, category: 'Sweets' },
      { name: 'Fish Chop (2 pcs)', description: 'Crispy spiced fish croquettes served with mustard dip', price_paise: 16000, is_veg: false, category: 'Snacks' },
      { name: 'Singara (Samosa 2 pcs)', description: 'Bengali style potato and peanut stuffed samosa', price_paise: 5000, is_veg: true, category: 'Snacks' },
      { name: 'Darjeeling Tea', description: 'Aromatic black tea from Darjeeling estates', price_paise: 4000, is_veg: true, category: 'Beverages' },
    ]
  }
];

async function seed() {
  const client = await pool.connect();
  try {
    console.log('Starting seed...');
    await client.query('BEGIN');

    for (const rData of sampleRestaurants) {
      // Check if restaurant already exists
      const existing = await client.query('SELECT id FROM restaurants WHERE name = $1', [rData.name]);
      let restaurantId;

      const imageUrl = `https://picsum.photos/seed/${rData.slug}/600/400`;

      if (existing.rows.length > 0) {
        restaurantId = existing.rows[0].id;
        console.log(`Restaurant '${rData.name}' already exists (${restaurantId}). Updating...`);
        await client.query(
          `UPDATE restaurants 
           SET cuisine = $1, image_url = $2, rating = $3, delivery_time_min = $4, 
               delivery_fee_paise = $5, lat = $6, lng = $7, is_open = $8
           WHERE id = $9`,
          [rData.cuisine, imageUrl, rData.rating, rData.delivery_time_min, rData.delivery_fee_paise, rData.lat, rData.lng, rData.is_open, restaurantId]
        );
      } else {
        const resInsert = await client.query(
          `INSERT INTO restaurants (name, cuisine, image_url, rating, delivery_time_min, delivery_fee_paise, lat, lng, is_open)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
           RETURNING id`,
          [rData.name, rData.cuisine, imageUrl, rData.rating, rData.delivery_time_min, rData.delivery_fee_paise, rData.lat, rData.lng, rData.is_open]
        );
        restaurantId = resInsert.rows[0].id;
        console.log(`Inserted restaurant '${rData.name}' (${restaurantId})`);
      }

      // Insert menu items safely
      for (const item of rData.items) {
        const itemImage = `https://picsum.photos/seed/${rData.slug}-${item.name.toLowerCase().replace(/[^a-z0-9]/g, '-')}/600/400`;
        const itemExisting = await client.query(
          'SELECT id FROM menu_items WHERE restaurant_id = $1 AND name = $2',
          [restaurantId, item.name]
        );

        if (itemExisting.rows.length > 0) {
          await client.query(
            `UPDATE menu_items
             SET description = $1, price_paise = $2, image_url = $3, is_veg = $4, category = $5
             WHERE id = $6`,
            [item.description, item.price_paise, itemImage, item.is_veg, item.category, itemExisting.rows[0].id]
          );
        } else {
          await client.query(
            `INSERT INTO menu_items (restaurant_id, name, description, price_paise, image_url, is_veg, category)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [restaurantId, item.name, item.description, item.price_paise, itemImage, item.is_veg, item.category]
          );
        }
      }
    }

    await client.query('COMMIT');
    console.log('Database seed completed successfully!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seed error:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
