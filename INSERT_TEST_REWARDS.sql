-- INSERTAR PRODUCTOS DE PRUEBA
INSERT INTO public.products (name, description, price, points_price, stock, image_url, is_active, shipping_option)
VALUES 
(
    'Wallpaper Exclusivo', 'Fondo de pantalla 4K.', 0, 100, 9999, 
    'https://images.unsplash.com/photo-1612036782180-6f0b6cd846fe?q=80&w=800', 
    true, 'stand_pickup'
),
(
    'Pack Stickers', 'Set para WhatsApp.', 0, 250, 9999, 
    'https://images.unsplash.com/photo-1572375992501-4b0892d50c69?q=80&w=800', 
    true, 'stand_pickup'
),
(
    'Ticket Sorteo VIP', 'Participa por un pase VIP.', 0, 500, 50, 
    'https://images.unsplash.com/photo-1549451371-64aa98a6f660?q=80&w=800', 
    true, 'stand_pickup'
),
(
    'Figura Mini', 'Figura aleatoria.', 50.00, 1500, 5, 
    'https://images.unsplash.com/photo-1608889175123-8ee362201f81?q=80&w=800', 
    true, 'stand_pickup'
);
