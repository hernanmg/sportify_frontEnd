import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/help/help_article.dart';

class HelpContent {
  HelpContent._();

  static const categories = [
    'Primeros pasos',
    'Equipo y plantel',
    'Partidos',
    'Eventos y calendario',
    'Finanzas',
    'Perfil y roles',
  ];

  static final List<HelpArticle> articles = [
    HelpArticle(
      id: 'inicio',
      title: 'Pantalla de inicio',
      summary:
          'Tu punto de partida con accesos rápidos a las secciones más usadas.',
      icon: Icons.home_outlined,
      color: Colors.blue,
      keywords: [
        'inicio',
        'home',
        'accesos',
        'rápidos',
        'bienvenida',
        'hola',
      ],
      steps: [
        'En Inicio ves tu nombre y tu rol (Jugador, DT, etc.).',
        'Usá los accesos rápidos para ir a Gestión Deportiva, Finanzas o Mis eventos.',
        'Si sos DT o capitán, también aparece el Panel del equipo.',
        'El ícono de ayuda (?) abre una búsqueda para encontrar guías al instante.',
      ],
      tip: 'Deslizá hacia abajo en Inicio para ver el banner de tu equipo activo.',
    ),
    HelpArticle(
      id: 'unirse-equipo',
      title: 'Unirse a un equipo',
      summary: 'Cómo ingresar con código de invitación o crear tu club.',
      icon: Icons.group_add_outlined,
      color: Colors.indigo,
      keywords: [
        'unirse',
        'código',
        'invitación',
        'equipo',
        'join',
        'club',
      ],
      steps: [
        'Pedile al DT o administrador el código de invitación del equipo.',
        'Andá a Perfil → Unirme a un equipo (o seguí el asistente al registrarte).',
        'Ingresá el código y confirmá.',
        'Si sos DT nuevo, completá el alta del equipo desde la configuración inicial.',
      ],
    ),
    HelpArticle(
      id: 'plantel',
      title: 'Plantel y roster',
      summary: 'Alta de jugadores, categorías, buena fe y dorsales.',
      icon: Icons.people_outline,
      color: Colors.green,
      keywords: [
        'plantel',
        'roster',
        'jugadores',
        'dorsal',
        'camiseta',
        'categoría',
        'buena fe',
        'invitado',
      ],
      steps: [
        'Entrá a Gestión Deportiva → Plantel.',
        'Filtrá por categoría o temporada según necesites.',
        'Agregá jugadores con app (vinculados) o sin app (invitados/guest).',
        'Asigná número de camiseta y estado de buena fe cuando corresponda.',
        'Los cambios impactan en convocatorias y alineaciones.',
      ],
      tip: 'Un jugador sin app puede sumarse al plantel y vincularse después.',
    ),
    HelpArticle(
      id: 'convocatoria',
      title: 'Convocatorias',
      summary: 'Armar, enviar y hacer seguimiento de quién va al partido.',
      icon: Icons.campaign_outlined,
      color: Colors.orange,
      keywords: [
        'convocatoria',
        'convocar',
        'confirmar',
        'rechazar',
        'plantel',
        'partido',
        'rival',
      ],
      steps: [
        'Desde Gestión Deportiva → Convocatorias, creá un borrador del partido.',
        'Elegí fecha, rival, lugar y jugadores convocados.',
        'Enviá la convocatoria: cada jugador recibe notificación.',
        'Los jugadores confirman o rechazan desde Mis eventos o la notificación.',
        'Como DT podés ver estadísticas de confirmados y pendientes.',
      ],
      tip: 'Podés guardar plantillas de convocatoria para partidos habituales.',
    ),
    HelpArticle(
      id: 'alineacion',
      title: 'Alineación y táctica',
      summary: 'Armá la formación en la cancha antes o después del partido.',
      icon: Icons.sports_soccer,
      color: Colors.teal,
      keywords: [
        'alineación',
        'táctica',
        'formación',
        'cancha',
        '4-4-2',
        'titular',
        'suplente',
        'dibujo',
        'lápiz',
      ],
      steps: [
        'Abrí Gestionar partido → pestaña Alineación.',
        'Elegí formación (4-4-2, 4-3-3, 3-5-2) y tocá jugadores en la barra inferior.',
        'Arrastrá jugadores en la cancha para ajustar posiciones.',
        'Usá el lápiz para marcar jugadas; guardá tácticas con nombre para reutilizar.',
        'Confirmá con Guardar alineación.',
      ],
      tip: 'Los confirmados aparecen primero en la barra inferior; también podés sumar otros convocados.',
    ),
    HelpArticle(
      id: 'gestionar-partido',
      title: 'Gestionar partido',
      summary: 'Asistencia, votaciones, estadísticas y cierre del encuentro.',
      icon: Icons.sports_score,
      color: Colors.deepPurple,
      keywords: [
        'gestionar',
        'partido',
        'post',
        'asistencia',
        'votación',
        'figura',
        'resultado',
        'resumen',
      ],
      steps: [
        'Tras enviar la convocatoria, abrí el partido desde Convocatorias → Gestionar partido.',
        'En Asistencia marcá quién estuvo presente.',
        'En Alineación definí titulares y posiciones.',
        'En Resumen ves puntuaciones, figura del partido y la cancha guardada.',
        'Cerrá votación y finalizá el partido cuando corresponda.',
      ],
    ),
    HelpArticle(
      id: 'eventos',
      title: 'Mis eventos',
      summary: 'Confirmaciones, eventos sociales y entrenamientos.',
      icon: Icons.event_available,
      color: Colors.purple,
      keywords: [
        'eventos',
        'entrenamiento',
        'social',
        'confirmar',
        'asistir',
        'crear evento',
      ],
      steps: [
        'En Mis eventos ves convocatorias pendientes y eventos del equipo.',
        'Confirmá o rechazá convocatorias con un toque.',
        'Cualquier miembro del equipo puede crear eventos (entrenamiento, social, etc.).',
        'Usá el menú ⋮ o el ícono de calendario para ver la agenda del equipo.',
      ],
    ),
    HelpArticle(
      id: 'calendario',
      title: 'Calendario del equipo',
      summary: 'Partidos, entrenamientos y cumpleaños en una sola vista.',
      icon: Icons.calendar_month_outlined,
      color: Colors.deepOrange,
      keywords: [
        'calendario',
        'cumpleaños',
        'fecha',
        'agenda',
        'mes',
      ],
      steps: [
        'Abrí Calendario desde Mis eventos o Gestión Deportiva.',
        'Los eventos aparecen en azul; los cumpleaños del plantel en morado.',
        'Filtrá por tipo: todo, solo eventos o solo cumpleaños.',
        'Doble toque en un día: crear evento (todos) o convocatoria (DT/admin).',
      ],
      tip: 'Completá tu fecha de nacimiento en el perfil para aparecer en cumpleaños.',
    ),
    HelpArticle(
      id: 'finanzas',
      title: 'Finanzas y cuotas',
      summary: 'Estado de cuenta, pagos, cuotas y movimientos del equipo.',
      icon: Icons.payments_outlined,
      color: Colors.teal,
      keywords: [
        'finanzas',
        'cuota',
        'pago',
        'moroso',
        'caja',
        'dinero',
        'recibo',
      ],
      steps: [
        'En Finanzas → Mi cuenta ves tu saldo y movimientos.',
        'Revisá cuotas pendientes y comprobantes si el DT las cargó.',
        'El Panel del equipo (DT/admin) muestra morosos y caja del mes.',
      ],
    ),
    HelpArticle(
      id: 'panel-equipo',
      title: 'Panel del equipo',
      summary: 'Vista DT/admin: morosos, asistencias y configuración.',
      icon: Icons.dashboard_customize_outlined,
      color: Colors.blueGrey,
      keywords: [
        'panel',
        'admin',
        'dt',
        'morosos',
        'asistencia',
        'cumpleaños',
        'notificación',
      ],
      steps: [
        'Accedé desde Inicio o el menú Más → Panel del equipo.',
        'Revisá confirmaciones, morosos y resumen de caja.',
        'Configurá la hora de aviso de cumpleaños del plantel (DT/admin).',
      ],
    ),
    HelpArticle(
      id: 'notificaciones',
      title: 'Notificaciones',
      summary: 'Convocatorias, recordatorios y cumpleaños.',
      icon: Icons.notifications_outlined,
      color: Colors.redAccent,
      keywords: [
        'notificación',
        'push',
        'aviso',
        'cumpleaños',
        'invitación',
      ],
      steps: [
        'Las convocatorias enviadas generan notificación a cada convocado.',
        'Respondé desde la notificación o desde Mis eventos.',
        'Los cumpleaños del plantel se avisan según la hora configurada por el DT.',
      ],
    ),
    HelpArticle(
      id: 'perfil',
      title: 'Perfil y datos personales',
      summary: 'Nombre, foto, fecha de nacimiento y de qué hincha sos.',
      icon: Icons.person_outline,
      color: Colors.cyan,
      keywords: [
        'perfil',
        'foto',
        'avatar',
        'nacimiento',
        'hincha',
        'ficha',
        'contraseña',
      ],
      steps: [
        'Tocá tu ícono de perfil en Inicio.',
        'Editá información básica: nombre, fecha de nacimiento, «De qué hincha sos».',
        'En Seguridad podés cambiar tu contraseña.',
      ],
    ),
    HelpArticle(
      id: 'roles',
      title: 'Roles: DT, jugador y admin',
      summary: 'Qué puede hacer cada rol en la app.',
      icon: Icons.badge_outlined,
      color: Colors.brown,
      keywords: [
        'rol',
        'dt',
        'director técnico',
        'jugador',
        'admin',
        'capitán',
        'permisos',
      ],
      steps: [
        'Jugador: confirma convocatorias, vota compañeros, ve finanzas propias.',
        'DT: gestiona plantel, convocatorias, alineación, panel del equipo.',
        'Admin/manager: además administra clubes, categorías y usuarios globales.',
        'Tu rol se muestra en Inicio y en tu perfil.',
      ],
    ),
    HelpArticle(
      id: 'equipo-config',
      title: 'Escudo y colores del equipo',
      summary: 'Personalizá la identidad visual de tu club.',
      icon: Icons.palette_outlined,
      color: Colors.pink,
      keywords: [
        'escudo',
        'logo',
        'colores',
        'equipo',
        'camiseta',
        'identidad',
      ],
      steps: [
        'Desde Gestión de equipos o edición del equipo, cargá el escudo.',
        'Elegí colores primario y secundario con presets o selector.',
        'Los colores se usan en la interfaz del equipo.',
      ],
    ),
  ];

  static String categoryFor(HelpArticle article) {
    switch (article.id) {
      case 'inicio':
      case 'unirse-equipo':
      case 'roles':
        return 'Primeros pasos';
      case 'plantel':
      case 'equipo-config':
      case 'panel-equipo':
        return 'Equipo y plantel';
      case 'convocatoria':
      case 'alineacion':
      case 'gestionar-partido':
        return 'Partidos';
      case 'eventos':
      case 'calendario':
      case 'notificaciones':
        return 'Eventos y calendario';
      case 'finanzas':
        return 'Finanzas';
      case 'perfil':
        return 'Perfil y roles';
      default:
        return 'Primeros pasos';
    }
  }

  static List<HelpArticle> search(String query) {
    return articles.where((a) => a.matchesQuery(query)).toList();
  }

  static HelpArticle? byId(String id) {
    for (final a in articles) {
      if (a.id == id) return a;
    }
    return null;
  }
}
