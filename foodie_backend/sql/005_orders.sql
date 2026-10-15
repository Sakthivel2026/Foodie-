CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  restaurant_id UUID NOT NULL REFERENCES restaurants(id),
  address_id UUID NOT NULL REFERENCES addresses(id),
  status VARCHAR(50) NOT NULL DEFAULT 'PENDING_PAYMENT',
  payment_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
  subtotal_paise INT NOT NULL,
  delivery_fee_paise INT NOT NULL,
  tax_paise INT NOT NULL,
  total_paise INT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES menu_items(id),
  name_snapshot VARCHAR(255) NOT NULL,
  price_paise_snapshot INT NOT NULL,
  quantity INT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
