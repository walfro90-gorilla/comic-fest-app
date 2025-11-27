import 'package:comic_fest/core/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class SeedService {
  final SupabaseService _supabase = SupabaseService.instance;
  final _uuid = const Uuid();

  Future<void> seedAllData() async {
    try {
      debugPrint('🌱 Starting seed process...');
      
      // 1. Profiles & Exhibitors
      final exhibitorIds = await seedExhibitors();

      // 2. Events & Contests
      final eventIds = await seedEvents();
      await seedContests();

      // 3. Products
      await seedProducts();

      // 4. Promotions
      await seedPromotions(exhibitorIds);

      // 5. Contestants
      await seedContestants(eventIds);
      
      debugPrint('✅ Seed process completed successfully!');
    } catch (e) {
      debugPrint('❌ Seed process failed: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> seedEvents() async {
    debugPrint('🎭 Seeding events...');
    
    final cosplayContestId = _uuid.v4();
    final kpopDanceContestId = _uuid.v4();
    final fanArtContestId = _uuid.v4();
    
    final events = [
      {
        'id': cosplayContestId,
        'title': 'Concurso de Cosplay 2025',
        'description': 'El concurso más esperado del año. Los mejores cosplayers compiten por el gran premio de \$10,000 MXN. Vota por tu favorito!',
        'category': 'concurso',
        'start_time': DateTime.now().add(const Duration(days: 3, hours: 18)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 3, hours: 21)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': kpopDanceContestId,
        'title': 'Concurso de Baile K-Pop',
        'description': 'Cover dance competition de los mejores grupos de K-Pop. Coreografías grupales e individuales. Premio: \$5,000 MXN y mercancía oficial.',
        'category': 'concurso',
        'start_time': DateTime.now().add(const Duration(days: 2, hours: 16)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 2, hours: 19)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': fanArtContestId,
        'title': 'Concurso de Fan Art',
        'description': 'Exhibición y votación de arte digital y tradicional. Categorías: manga/anime, cómics occidentales, y videojuegos. Los ganadores serán expuestos en la galería oficial.',
        'category': 'concurso',
        'start_time': DateTime.now().add(const Duration(days: 4, hours: 13)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 4, hours: 16)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Panel: El Futuro del Manga en México',
        'description': 'Conversatorio con editores y mangakas mexicanos sobre la industria del manga en Latinoamérica. Moderado por Rafael Aviña.',
        'category': 'panel',
        'start_time': DateTime.now().add(const Duration(days: 2, hours: 10)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 2, hours: 11, minutes: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Firma de Autógrafos: Edgar Delgado',
        'description': 'El reconocido colorista de Marvel Comics (Spider-Man, Daredevil) firmará cómics y posters. ¡Trae tus ejemplares favoritos!',
        'category': 'firma',
        'start_time': DateTime.now().add(const Duration(days: 2, hours: 12)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 2, hours: 13, minutes: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Torneo de Cosplay: Marvel vs DC',
        'description': 'Competencia épica donde equipos representan universos Marvel y DC. Premios en efectivo y mercancía exclusiva. Registro presencial.',
        'category': 'torneo',
        'start_time': DateTime.now().add(const Duration(days: 2, hours: 15)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 2, hours: 18)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Taller: Introducción al Dibujo de Manga',
        'description': 'Aprende técnicas básicas de dibujo manga con la artista Karla Díaz. Materiales incluidos. Cupo limitado a 30 personas.',
        'category': 'actividad',
        'start_time': DateTime.now().add(const Duration(days: 2, hours: 14)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 2, hours: 16)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Panel: Cómo Crear tu Propio Webcomic',
        'description': 'Expertos en narrativa digital comparten consejos para publicar tu webcomic. Incluye distribución, monetización y marketing.',
        'category': 'panel',
        'start_time': DateTime.now().add(const Duration(days: 3, hours: 10)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 3, hours: 11, minutes: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Firma de Autógrafos: Bachan',
        'description': 'El ilustrador mexicano de Dota 2 y League of Legends estará firmando prints y arte original. No te pierdas esta oportunidad única.',
        'category': 'firma',
        'start_time': DateTime.now().add(const Duration(days: 3, hours: 13)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 3, hours: 14, minutes: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Torneo: Super Smash Bros Ultimate',
        'description': 'Competencia oficial con brackets profesionales. Primer lugar: \$3,000 MXN. Inscripción en el área de gaming desde las 9am.',
        'category': 'torneo',
        'start_time': DateTime.now().add(const Duration(days: 3, hours: 11)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 3, hours: 17)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Actividad: Karaoke Anime',
        'description': 'Canta tus openings favoritos de anime frente al público. Premios para las mejores interpretaciones. ¡Demuestra tu pasión!',
        'category': 'actividad',
        'start_time': DateTime.now().add(const Duration(days: 3, hours: 16)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 3, hours: 19)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Panel: La Era Dorada del Cómic Mexicano',
        'description': 'Historiadores y coleccionistas analizan la época de oro del cómic mexicano con Kalimán, Memín y Lágrimas y Risas.',
        'category': 'panel',
        'start_time': DateTime.now().add(const Duration(days: 4, hours: 10, minutes: 30)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 4, hours: 12)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Firma de Autógrafos: Patricio Oliver',
        'description': 'El creador de "Rocko" estará presente para firmar ejemplares de su obra. Conoce la historia detrás de este ícono del cómic nacional.',
        'category': 'firma',
        'start_time': DateTime.now().add(const Duration(days: 4, hours: 14)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 4, hours: 15, minutes: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Torneo: Concurso de Disfraces Infantil',
        'description': 'Los pequeños fans muestran sus mejores cosplays. Categorías: Marvel, DC, Anime, y Videojuegos. Premios para todos los participantes.',
        'category': 'torneo',
        'start_time': DateTime.now().add(const Duration(days: 4, hours: 12)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 4, hours: 13, minutes: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Taller: Maquillaje FX para Cosplay',
        'description': 'Aprende técnicas profesionales de caracterización y maquillaje de efectos especiales. Trae tu kit básico de maquillaje.',
        'category': 'actividad',
        'start_time': DateTime.now().add(const Duration(days: 4, hours: 15)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 4, hours: 17, minutes: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Panel: Animación Mexicana: Del Papel a la Pantalla',
        'description': 'Creadores de estudios de animación mexicanos hablan sobre producción, financiamiento y distribución internacional.',
        'category': 'panel',
        'start_time': DateTime.now().add(const Duration(days: 4, hours: 16)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 4, hours: 17, minutes: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Actividad: Trivia Geek: Universo Marvel',
        'description': 'Demuestra tus conocimientos sobre el MCU, cómics clásicos y personajes obscuros. Los ganadores se llevan funko pops exclusivos.',
        'category': 'actividad',
        'start_time': DateTime.now().add(const Duration(days: 4, hours: 18)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 4, hours: 19)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'title': 'Torneo: Magic The Gathering - Commander',
        'description': 'Torneo formato Commander con pods de 4 jugadores. Power level 7-8. Premios: sobres de ediciones recientes y playmat exclusivo.',
        'category': 'torneo',
        'start_time': DateTime.now().add(const Duration(days: 4, hours: 10)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 4, hours: 15)).toIso8601String(),
        'is_active': true,
      },
    ];

    final result = await _supabase.client
        .from('schedule_items')
        .insert(events)
        .select();
    
    debugPrint('✅ Seeded ${events.length} events');
    debugPrint('📋 Inserted events: ${result.map((e) => e['id']).toList()}');
    
    // Verify the IDs match what we expect
    Map<String, dynamic>? insertedCosplay;
    Map<String, dynamic>? insertedKpop;
    Map<String, dynamic>? insertedFanArt;
    
    for (final event in result as List) {
      if (event['title'] == 'Concurso de Cosplay 2025') {
        insertedCosplay = event;
      } else if (event['title'] == 'Concurso de Baile K-Pop') {
        insertedKpop = event;
      } else if (event['title'] == 'Concurso de Fan Art') {
        insertedFanArt = event;
      }
    }
    
    final actualCosplayId = insertedCosplay?['id'] as String?;
    final actualKpopId = insertedKpop?['id'] as String?;
    final actualFanArtId = insertedFanArt?['id'] as String?;
    
    debugPrint('🎯 Expected Cosplay ID: $cosplayContestId');
    debugPrint('🎯 Actual Cosplay ID:   $actualCosplayId');
    debugPrint('🎯 Expected K-Pop ID: $kpopDanceContestId');
    debugPrint('🎯 Actual K-Pop ID:   $actualKpopId');
    debugPrint('🎯 Expected Fan Art ID: $fanArtContestId');
    debugPrint('🎯 Actual Fan Art ID:   $actualFanArtId');
    
    return {
      'cosplayContest': actualCosplayId ?? cosplayContestId,
      'kpopDanceContest': actualKpopId ?? kpopDanceContestId,
      'fanArtContest': actualFanArtId ?? fanArtContestId,
    };
  }

  Future<void> seedProducts() async {
    debugPrint('🛍️ Seeding products...');
    
    final products = [
      {
        'id': _uuid.v4(),
        'name': 'Playera Oficial Comic Fest 2025',
        'description': 'Playera 100% algodón con diseño exclusivo del festival. Disponible en negro, blanco y gris. Tallas: S, M, L, XL, XXL.',
        'price': 350.0,
        'image_url': 'https://via.placeholder.com/300x400/2196F3/FFFFFF?text=Playera+Comic+Fest',
        'stock': 150,
        'is_active': true,
        'is_exclusive': false,
      },
      {
        'id': _uuid.v4(),
        'name': 'Gorra Comic Fest Edición Limitada',
        'description': 'Gorra snapback bordada con logo holográfico del festival. Edición limitada de 200 unidades numeradas.',
        'price': 280.0,
        'points_price': 500,
        'image_url': 'https://via.placeholder.com/300x400/FF5722/FFFFFF?text=Gorra+Limitada',
        'stock': 85,
        'is_active': true,
        'is_exclusive': true,
      },
      {
        'id': _uuid.v4(),
        'name': 'Poster Conmemorativo A2',
        'description': 'Poster oficial del Comic Fest 2025 diseñado por artistas locales. Tamaño A2 (42x59cm), papel couché 250g.',
        'price': 150.0,
        'image_url': 'https://via.placeholder.com/300x400/9C27B0/FFFFFF?text=Poster+A2',
        'stock': 300,
        'is_active': true,
        'is_exclusive': false,
      },
      {
        'id': _uuid.v4(),
        'name': 'Taza de Colección Comic Fest',
        'description': 'Taza de cerámica premium con arte original. Capacidad 350ml. Apta para microondas y lavavajillas.',
        'price': 180.0,
        'points_price': 300,
        'image_url': 'https://via.placeholder.com/300x400/4CAF50/FFFFFF?text=Taza+Oficial',
        'stock': 120,
        'is_active': true,
        'is_exclusive': false,
      },
      {
        'id': _uuid.v4(),
        'name': 'Pin Set Exclusivo (5 piezas)',
        'description': 'Set de 5 pins esmaltados con personajes icónicos y logo del festival. Incluye estuche de colección.',
        'price': 250.0,
        'points_price': 450,
        'image_url': 'https://via.placeholder.com/300x400/FFC107/000000?text=Pin+Set',
        'stock': 200,
        'is_active': true,
        'is_exclusive': true,
      },
      {
        'id': _uuid.v4(),
        'name': 'Mochila Comic Fest 2025',
        'description': 'Mochila resistente con compartimento para laptop 15". Múltiples bolsillos y diseño exclusivo bordado.',
        'price': 650.0,
        'image_url': 'https://via.placeholder.com/300x400/607D8B/FFFFFF?text=Mochila',
        'stock': 50,
        'is_active': true,
        'is_exclusive': false,
      },
      {
        'id': _uuid.v4(),
        'name': 'Llavero Metálico Edición VIP',
        'description': 'Llavero de metal con baño dorado y cristales incrustados. Exclusivo para asistentes VIP.',
        'price': 120.0,
        'points_price': 800,
        'image_url': 'https://via.placeholder.com/300x400/FFD700/000000?text=Llavero+VIP',
        'stock': 100,
        'is_active': true,
        'is_exclusive': true,
      },
      {
        'id': _uuid.v4(),
        'name': 'Sudadera Premium Comic Fest',
        'description': 'Sudadera con capucha, bolsillo canguro y forro polar. Estampado de alta calidad en frente y espalda.',
        'price': 550.0,
        'image_url': 'https://via.placeholder.com/300x400/000000/FFFFFF?text=Sudadera',
        'stock': 80,
        'is_active': true,
        'is_exclusive': false,
      },
      {
        'id': _uuid.v4(),
        'name': 'Sticker Pack (20 unidades)',
        'description': 'Pack de 20 stickers resistentes al agua con diseños variados del festival y cultura geek.',
        'price': 80.0,
        'points_price': 150,
        'image_url': 'https://via.placeholder.com/300x400/FF4081/FFFFFF?text=Stickers',
        'stock': 500,
        'is_active': true,
        'is_exclusive': false,
      },
      {
        'id': _uuid.v4(),
        'name': 'Figura de Acción Mascota Oficial',
        'description': 'Figura coleccionable de la mascota oficial del Comic Fest. Articulada, 15cm de altura. Edición limitada 500 unidades.',
        'price': 450.0,
        'points_price': 1000,
        'image_url': 'https://via.placeholder.com/300x400/E91E63/FFFFFF?text=Figura+Mascota',
        'stock': 150,
        'is_active': true,
        'is_exclusive': true,
      },
      {
        'id': _uuid.v4(),
        'name': 'Termo de Acero Inoxidable',
        'description': 'Termo térmico 500ml con diseño del festival. Mantiene bebidas frías/calientes por 12 horas.',
        'price': 320.0,
        'image_url': 'https://via.placeholder.com/300x400/00BCD4/FFFFFF?text=Termo',
        'stock': 100,
        'is_active': true,
        'is_exclusive': false,
      },
      {
        'id': _uuid.v4(),
        'name': 'Libreta de Artista Comic Fest',
        'description': 'Libreta premium de 120 páginas con papel de dibujo 120g. Incluye separadores y bolsillo interno.',
        'price': 200.0,
        'points_price': 350,
        'image_url': 'https://via.placeholder.com/300x400/795548/FFFFFF?text=Libreta',
        'stock': 180,
        'is_active': true,
        'is_exclusive': false,
      },
    ];

    try {
      final result = await _supabase.client.from('products').insert(products).select();
      debugPrint('✅ Seeded ${products.length} products');
      debugPrint('📦 Products inserted: ${result.map((p) => '${p['name']} (${p['id']})').join(', ')}');
    } catch (e) {
      debugPrint('❌ Products seeding failed: $e');
      // Detect common RLS error to provide a clearer hint in UI/logs
      final msg = e.toString();
      if (msg.contains('42501') || msg.toLowerCase().contains('row-level security')) {
        throw Exception(
          'RLS de products bloquea INSERT. Agrega las políticas para admin/staff en Supabase y reintenta.'
        );
      }
      rethrow;
    }
  }

  Future<void> seedContestants(Map<String, String> eventIds) async {
    debugPrint('🎭 Seeding contestants...');
    
    final cosplayContestId = eventIds['cosplayContest'];
    final kpopDanceContestId = eventIds['kpopDanceContest'];
    final fanArtContestId = eventIds['fanArtContest'];

    debugPrint('📝 Contest IDs - Cosplay: $cosplayContestId, K-Pop: $kpopDanceContestId, Fan Art: $fanArtContestId');

    final contestants = <Map<String, dynamic>>[];

    // Concurso de Cosplay
    if (cosplayContestId != null) {
      debugPrint('🎭 Adding cosplay contestants...');
      contestants.addAll([
        {
          'id': _uuid.v4(),
          'schedule_item_id': cosplayContestId,
          'name': 'Luna Starfire',
          'description': 'Cosplay de Sailor Moon con efectos de luz LED integrados',
          'contestant_number': 1,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': cosplayContestId,
          'name': 'Dark Phoenix Rising',
          'description': 'Interpretación épica de Jean Grey con alas mecánicas',
          'contestant_number': 2,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': cosplayContestId,
          'name': 'Mecha Goku',
          'description': 'Fusión única de Dragon Ball y armadura robótica',
          'contestant_number': 3,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': cosplayContestId,
          'name': 'Valkyrie of Asgard',
          'description': 'Valkyrie de Thor Ragnarok con armadura detallada',
          'contestant_number': 4,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': cosplayContestId,
          'name': 'Cyberpunk Spidey',
          'description': 'Spider-Man 2099 con elementos neon y holográficos',
          'contestant_number': 5,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': cosplayContestId,
          'name': 'Queen of Hearts',
          'description': 'Reina de Corazones de Alicia con vestido victoriano',
          'contestant_number': 6,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': cosplayContestId,
          'name': 'Arthas Lich King',
          'description': 'Rey Exánime de Warcraft con Frostmourne iluminada',
          'contestant_number': 7,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': cosplayContestId,
          'name': 'Harley Quinn Vintage',
          'description': 'Harley Quinn versión clásica animada de los 90s',
          'contestant_number': 8,
        },
      ]);
    }

    // Concurso de Baile K-Pop
    if (kpopDanceContestId != null) {
      debugPrint('🎤 Adding K-Pop contestants...');
      contestants.addAll([
        {
          'id': _uuid.v4(),
          'schedule_item_id': kpopDanceContestId,
          'name': 'Seoul Stars',
          'description': 'Cover de BTS - "Dynamite" con coreografía sincronizada perfecta',
          'contestant_number': 1,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': kpopDanceContestId,
          'name': 'BlackPink Warriors',
          'description': 'Medley de éxitos de BlackPink con vestuario auténtico',
          'contestant_number': 2,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': kpopDanceContestId,
          'name': 'Stray Cats MX',
          'description': 'Interpretación energética de Stray Kids - "God\'s Menu"',
          'contestant_number': 3,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': kpopDanceContestId,
          'name': 'Twice Delight',
          'description': 'Cover dulce y divertido de Twice - "TT" y "Fancy"',
          'contestant_number': 4,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': kpopDanceContestId,
          'name': 'EXO Elite',
          'description': 'Coreografía compleja de EXO - "Love Shot" con efectos visuales',
          'contestant_number': 5,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': kpopDanceContestId,
          'name': 'NewJeans Fresh',
          'description': 'Cover juvenil de NewJeans - "Hype Boy" con props',
          'contestant_number': 6,
        },
      ]);
    }

    // Concurso de Fan Art
    if (fanArtContestId != null) {
      debugPrint('🎨 Adding Fan Art contestants...');
      contestants.addAll([
        {
          'id': _uuid.v4(),
          'schedule_item_id': fanArtContestId,
          'name': 'Sakura Dreams - Ana Martínez',
          'description': 'Ilustración digital de Naruto en estilo acuarela japonesa',
          'contestant_number': 1,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': fanArtContestId,
          'name': 'Gotham Noir - Carlos Vega',
          'description': 'Batman en técnica mixta con elementos de cómic clásico',
          'contestant_number': 2,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': fanArtContestId,
          'name': 'Pixel Paradise - Diana Chen',
          'description': 'Zelda en pixel art detallado con 32 colores',
          'contestant_number': 3,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': fanArtContestId,
          'name': 'Cosmic Marvel - Roberto Sánchez',
          'description': 'Ilustración épica de los Guardianes de la Galaxia en óleo digital',
          'contestant_number': 4,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': fanArtContestId,
          'name': 'Studio Ghibli Tribute - Laura Kim',
          'description': 'Paisaje original inspirado en Totoro con técnica tradicional',
          'contestant_number': 5,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': fanArtContestId,
          'name': 'Cyberpunk 2077 Redux - Miguel Torres',
          'description': 'V en la Ciudad de la Noche con iluminación neon impresionante',
          'contestant_number': 6,
        },
        {
          'id': _uuid.v4(),
          'schedule_item_id': fanArtContestId,
          'name': 'One Piece Legends - Sofia Ramírez',
          'description': 'Los Mugiwaras en estilo manga tradicional con tinta y plumilla',
          'contestant_number': 7,
        },
      ]);
    }

    if (contestants.isEmpty) {
      debugPrint('⚠️ No contest IDs found, skipping contestants seed');
      return;
    }

    debugPrint('📊 Total contestants to insert: ${contestants.length}');
    
    try {
      await _supabase.client.from('contestants').insert(contestants);
      debugPrint('✅ Seeded ${contestants.length} contestants across ${eventIds.length} contests');
    } catch (e) {
      debugPrint('❌ Contestants seeding failed: $e');
      debugPrint('Error details: $e');
      rethrow;
    }
  }

  Future<List<String>> seedExhibitors() async {
    debugPrint('🏢 Seeding exhibitors...');
    final exhibitorIds = <String>[];
    
    // 1. Create Profiles
    final profiles = [
      {
        'id': _uuid.v4(),
        'role': 'exhibitor',
        'username': 'comic_store_mx',
        'bio': 'La mejor tienda de cómics de México',
        'avatar_url': 'https://via.placeholder.com/150/0000FF/808080?text=CS',
      },
      {
        'id': _uuid.v4(),
        'role': 'exhibitor',
        'username': 'anime_shop_pro',
        'bio': 'Figuras y coleccionables de anime',
        'avatar_url': 'https://via.placeholder.com/150/FF0000/FFFFFF?text=AS',
      },
      {
        'id': _uuid.v4(),
        'role': 'exhibitor',
        'username': 'geek_world',
        'bio': 'Todo para el verdadero geek',
        'avatar_url': 'https://via.placeholder.com/150/008000/FFFFFF?text=GW',
      },
    ];

    try {
      await _supabase.client.from('profiles').upsert(profiles);
      
      // 2. Create Exhibitor Details
      final exhibitors = [
        {
          'profile_id': profiles[0]['id'],
          'company_name': 'Comic Store MX',
          'is_featured': true,
          'website_url': 'https://comicstoremx.com',
        },
        {
          'profile_id': profiles[1]['id'],
          'company_name': 'Anime Shop Pro',
          'is_featured': true,
          'website_url': 'https://animeshop.pro',
        },
        {
          'profile_id': profiles[2]['id'],
          'company_name': 'Geek World',
          'is_featured': false,
          'website_url': 'https://geekworld.mx',
        },
      ];

      await _supabase.client.from('exhibitor_details').upsert(exhibitors);
      exhibitorIds.addAll(profiles.map((p) => p['id'] as String));
      
      debugPrint('✅ Seeded ${exhibitors.length} exhibitors');
      return exhibitorIds;
    } catch (e) {
      debugPrint('❌ Exhibitors seeding failed: $e');
      // Non-critical, return empty to allow other seeds to proceed if possible
      return [];
    }
  }

  Future<void> seedContests() async {
    debugPrint('🏆 Seeding contests...');
    
    final contests = [
      {
        'id': _uuid.v4(),
        'name': 'Pasarela Cosplay Pro',
        'category': 'Cosplay',
        'description': 'Vota por el mejor traje de la categoría profesional.',
        'voting_start': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'voting_end': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'name': 'Ilustración Digital',
        'category': 'Arte',
        'description': 'Concurso de dibujo digital en vivo.',
        'voting_start': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        'voting_end': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'name': 'Mejor Stand 2025',
        'category': 'Expositores',
        'description': 'Elige el stand con la mejor decoración.',
        'voting_start': DateTime.now().toIso8601String(),
        'voting_end': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'is_active': true,
      },
    ];

    try {
      await _supabase.client.from('contests').insert(contests);
      debugPrint('✅ Seeded ${contests.length} contests');
    } catch (e) {
      debugPrint('❌ Contests seeding failed: $e');
    }
  }

  Future<void> seedPromotions(List<String> exhibitorIds) async {
    if (exhibitorIds.isEmpty) {
      debugPrint('⚠️ No exhibitors found, skipping promotions seed');
      return;
    }
    
    debugPrint('⚡ Seeding promotions...');
    
    final promotions = [
      {
        'id': _uuid.v4(),
        'exhibitor_id': exhibitorIds[0], // Comic Store MX
        'title': '20% en Funko Pops',
        'description': 'Descuento en todas las figuras Funko Pop regulares.',
        'discount_percent': 20,
        'valid_until': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
        'is_flash': true,
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'exhibitor_id': exhibitorIds[0],
        'title': '3x2 en Cómics Panini',
        'description': 'Compra 3 y paga 2 en todos los mangas y cómics de Panini.',
        'discount_percent': 33,
        'valid_until': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'is_flash': true,
        'is_active': true,
      },
      {
        'id': _uuid.v4(),
        'exhibitor_id': exhibitorIds[1], // Anime Shop Pro
        'title': 'Figura Demon Slayer -50%',
        'description': 'Descuento masivo en figuras seleccionadas de Kimetsu no Yaiba.',
        'discount_percent': 50,
        'valid_until': DateTime.now().add(const Duration(minutes: 45)).toIso8601String(),
        'is_flash': true,
        'is_active': true,
      },
    ];

    try {
      await _supabase.client.from('promotions').insert(promotions);
      debugPrint('✅ Seeded ${promotions.length} promotions');
    } catch (e) {
      debugPrint('❌ Promotions seeding failed: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      debugPrint('🗑️ Clearing all seed data...');
      
      // Using a valid UUID as a safe universal "not equal" target to delete all rows
      // This avoids the Postgres UUID cast error caused by empty-string filters.
      const safeUuid = '00000000-0000-0000-0000-000000000000';

      await _supabase.client.from('promotions').delete().neq('id', safeUuid);
      await _supabase.client.from('contests').delete().neq('id', safeUuid);
      await _supabase.client.from('contestants').delete().neq('id', safeUuid);
      await _supabase.client.from('schedule_items').delete().neq('id', safeUuid);
      await _supabase.client.from('products').delete().neq('id', safeUuid);
      await _supabase.client.from('exhibitor_details').delete().neq('profile_id', safeUuid);
      // Note: We don't delete profiles to avoid messing with auth, but in a pure seed env we might.
      // For now, we leave profiles as they might be linked to auth users.
      
      debugPrint('✅ All data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear data: $e');
      rethrow;
    }
  }
}
