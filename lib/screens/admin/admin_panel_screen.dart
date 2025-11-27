import 'package:comic_fest/models/user_model.dart';
import 'package:comic_fest/models/event_model.dart';
import 'package:comic_fest/models/contestant_model.dart';
import 'package:comic_fest/models/ticket_model.dart';
import 'package:comic_fest/models/product_model.dart';
import 'package:comic_fest/models/panel_vote_model.dart';
import 'package:comic_fest/models/points_transaction_model.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:comic_fest/services/seed_service.dart';
import 'package:comic_fest/services/event_service.dart';
import 'package:comic_fest/services/contestant_service.dart';
import 'package:comic_fest/services/ticket_service.dart';
import 'package:comic_fest/services/points_service.dart';
import 'package:comic_fest/services/voting_service.dart';
import 'package:comic_fest/core/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final EventService _eventService = EventService();
  final ContestantService _contestantService = ContestantService();
  final TicketService _ticketService = TicketService();
  final PointsService _pointsService = PointsService();
  final VotingService _votingService = VotingService();
  final SupabaseService _supabase = SupabaseService.instance;
  
  List<UserModel> _users = [];
  List<EventModel> _events = [];
  List<ProductModel> _products = [];
  List<TicketModel> _tickets = [];
  List<ContestantModel> _contestants = [];
  List<PanelVoteModel> _votes = [];
  List<PointsTransactionModel> _transactions = [];
  
  bool _isLoading = true;
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadDataForCurrentTab();
      }
    });
    _loadDataForCurrentTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDataForCurrentTab() async {
    switch (_tabController.index) {
      case 0:
        await _loadUsers();
        break;
      case 1:
        await _loadEvents();
        break;
      case 2:
        await _loadProducts();
        break;
      case 3:
        await _loadTickets();
        break;
      case 4:
        await _loadContestants();
        break;
      case 5:
        await _loadVotes();
        break;
      case 6:
        await _loadTransactions();
        break;
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _eventService.getEvents(forceRefresh: true);
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar eventos: $e')),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.client
          .from('products')
          .select()
          .order('updated_at', ascending: false);
      final products = (response as List).map((json) {
        // Handle missing created_at field gracefully
        if (json['created_at'] == null) {
          json['created_at'] = json['updated_at'] ?? DateTime.now().toIso8601String();
        }
        return ProductModel.fromJson(json);
      }).toList();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.client
          .from('tickets')
          .select()
          .order('purchase_date', ascending: false);
      final tickets = (response as List).map((json) => TicketModel.fromJson(json)).toList();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tickets: $e')),
        );
      }
    }
  }

  Future<void> _loadContestants() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.client
          .from('contestants')
          .select()
          .order('created_at', ascending: false);
      final contestants = (response as List).map((json) => ContestantModel.fromJson(json)).toList();
      setState(() {
        _contestants = contestants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar concursantes: $e')),
        );
      }
    }
  }

  Future<void> _loadVotes() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.client
          .from('panel_votes')
          .select()
          .order('created_at', ascending: false);
      final votes = (response as List).map((json) {
        // Handle missing fields gracefully
        json['points'] = json['points'] ?? 1;
        json['synced'] = json['synced'] ?? true;
        return PanelVoteModel.fromJson(json);
      }).toList();
      setState(() {
        _votes = votes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading votes: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar votos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.client
          .from('points_log')
          .select()
          .order('created_at', ascending: false);
      final transactions = (response as List).map((json) {
        final pointsChange = json['points_change'] as int? ?? 0;
        return PointsTransactionModel(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          amount: pointsChange.abs(),
          type: pointsChange > 0 ? TransactionType.earn : TransactionType.spend,
          reason: json['reason'] as String? ?? 'Sin descripción',
          createdAt: json['created_at'] is String
              ? DateTime.parse(json['created_at'])
              : (json['created_at'] as DateTime),
          synced: json['synced'] as bool? ?? true,
        );
      }).toList();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar transacciones: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<UserModel> get _filteredUsers {
    if (_filterRole == 'all') return _users;
    return _users.where((u) => u.role.name == _filterRole).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context).pushNamed('/scan-tickets'),
            tooltip: 'Escanear Boletos',
          ),
          IconButton(
            icon: const Icon(Icons.data_object),
            onPressed: () => _showDataManagementDialog(),
            tooltip: 'Gestión de Datos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDataForCurrentTab,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Usuarios', icon: Icon(Icons.people, size: 18)),
            Tab(text: 'Eventos', icon: Icon(Icons.event, size: 18)),
            Tab(text: 'Productos', icon: Icon(Icons.shopping_bag, size: 18)),
            Tab(text: 'Tickets', icon: Icon(Icons.confirmation_number, size: 18)),
            Tab(text: 'Concursantes', icon: Icon(Icons.star, size: 18)),
            Tab(text: 'Votos', icon: Icon(Icons.how_to_vote, size: 18)),
            Tab(text: 'Puntos', icon: Icon(Icons.monetization_on, size: 18)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildEventsTab(),
                _buildProductsTab(),
                _buildTicketsTab(),
                _buildContestantsTab(),
                _buildVotesTab(),
                _buildTransactionsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateUserDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Crear Usuario'),
            )
          : null,
    );
  }

  Widget _buildUsersTab() => Column(
        children: [
          _buildStatsCards(),
          _buildFilterChips(),
          Expanded(child: _buildUsersList()),
        ],
      );

  Widget _buildEventsTab() => Column(
        children: [
          _buildEventsStatsCards(),
          Expanded(
            child: _buildDataList<EventModel>(
              data: _events,
              itemBuilder: (event) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(event.category),
                  child: Icon(_getCategoryIcon(event.category), color: Colors.white, size: 20),
                ),
                title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${event.category.name.toUpperCase()} • ${DateFormat('dd/MMM HH:mm').format(event.startTime)}'),
                trailing: event.isActive ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.cancel, color: Colors.grey),
              ),
            ),
          ),
        ],
      );

  Widget _buildProductsTab() => Column(
        children: [
          _buildProductsStatsCards(),
          Expanded(
            child: _buildDataList<ProductModel>(
              data: _products,
              itemBuilder: (product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.isExclusive ? Colors.orange : Colors.blue,
                  child: Icon(product.isExclusive ? Icons.star : Icons.shopping_bag, color: Colors.white, size: 20),
                ),
                title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock: ${product.stock} • \$${product.price.toStringAsFixed(2)}'),
                    if (product.pointsPrice != null)
                      Text('Puntos: ${product.pointsPrice}', style: TextStyle(color: Colors.amber, fontSize: 12)),
                  ],
                ),
                trailing: product.isExclusive
                    ? const Chip(label: Text('Exclusivo'), backgroundColor: Colors.orange, padding: EdgeInsets.zero)
                    : null,
              ),
            ),
          ),
        ],
      );

  Widget _buildTicketsTab() => _buildDataList<TicketModel>(
        data: _tickets,
        itemBuilder: (ticket) => ListTile(
          leading: CircleAvatar(
            backgroundColor: _getPaymentStatusColor(ticket.paymentStatus),
            child: Icon(_getPaymentStatusIcon(ticket.paymentStatus), color: Colors.white, size: 20),
          ),
          title: Text(ticket.ticketType, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('\$${ticket.price.toStringAsFixed(2)} • ${DateFormat('dd/MMM/yyyy').format(ticket.purchaseDate)}'),
          trailing: ticket.isValidated ? const Chip(label: Text('Validado'), backgroundColor: Colors.green) : null,
        ),
      );

  Widget _buildContestantsTab() => _buildDataList<ContestantModel>(
        data: _contestants,
        itemBuilder: (contestant) => ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple,
            child: Text('#${contestant.contestantNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(contestant.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(contestant.description ?? 'Sin descripción', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Chip(label: Text('${contestant.voteCount} votos'), padding: EdgeInsets.zero),
        ),
      );

  Widget _buildVotesTab() => _buildDataList<PanelVoteModel>(
        data: _votes,
        itemBuilder: (vote) => ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.amber,
            child: Icon(Icons.how_to_vote, color: Colors.white, size: 20),
          ),
          title: Text('Voto ID: ${vote.id.substring(0, 8)}...', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('Puntos: ${vote.points} • ${DateFormat('dd/MMM HH:mm').format(vote.createdAt)}'),
          trailing: vote.synced ? const Icon(Icons.cloud_done, color: Colors.green) : const Icon(Icons.cloud_off, color: Colors.grey),
        ),
      );

  Widget _buildTransactionsTab() => Column(
        children: [
          _buildPointsStatsCards(),
          Expanded(
            child: _buildDataList<PointsTransactionModel>(
              data: _transactions,
              itemBuilder: (transaction) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.type == TransactionType.earn ? Colors.green : Colors.red,
                  child: Icon(
                    transaction.type == TransactionType.earn ? Icons.add : Icons.remove,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(transaction.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(DateFormat('dd/MMM HH:mm').format(transaction.createdAt)),
                trailing: Text(
                  '${transaction.type == TransactionType.earn ? '+' : '-'}${transaction.amount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.type == TransactionType.earn ? Colors.green : Colors.red,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildDataList<T>({
    required List<T> data,
    required Widget Function(T) itemBuilder,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No hay datos disponibles', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: itemBuilder(data[index]),
      ),
    );
  }

  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.panel:
        return Icons.campaign;
      case EventCategory.firma:
        return Icons.edit;
      case EventCategory.torneo:
        return Icons.sports_esports;
      case EventCategory.concurso:
        return Icons.emoji_events;
      case EventCategory.actividad:
        return Icons.celebration;
    }
  }

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.panel:
        return Colors.blue;
      case EventCategory.firma:
        return Colors.purple;
      case EventCategory.torneo:
        return Colors.red;
      case EventCategory.concurso:
        return Colors.orange;
      case EventCategory.actividad:
        return Colors.green;
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.approved:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.replay;
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.approved:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.grey;
    }
  }

  Widget _buildStatsCards() {
    final stats = {
      'Total': _users.length,
      'Admins': _users.where((u) => u.role == UserRole.admin).length,
      'Staff': _users.where((u) => u.role == UserRole.staff).length,
      'Exhibitors': _users.where((u) => u.role == UserRole.exhibitor).length,
      'Artists': _users.where((u) => u.role == UserRole.artist).length,
      'Attendees': _users.where((u) => u.role == UserRole.attendee).length,
    };

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final entry = stats.entries.elementAt(index);
          return Card(
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsStatsCards() {
    final stats = {
      'Total': _events.length,
      'Activos': _events.where((e) => e.isActive).length,
      'Paneles': _events.where((e) => e.category == EventCategory.panel).length,
      'Concursos': _events.where((e) => e.category == EventCategory.concurso).length,
      'Torneos': _events.where((e) => e.category == EventCategory.torneo).length,
    };

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final entry = stats.entries.elementAt(index);
          return Card(
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${entry.value}', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(entry.key, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsStatsCards() {
    final totalStock = _products.fold<int>(0, (sum, p) => sum + p.stock);
    final totalValue = _products.fold<double>(0, (sum, p) => sum + (p.price * p.stock));
    final stats = {
      'Total': _products.length,
      'Stock Total': totalStock,
      'Exclusivos': _products.where((p) => p.isExclusive).length,
      'Con Puntos': _products.where((p) => p.pointsPrice != null).length,
      'Valor': '\$${totalValue.toStringAsFixed(0)}',
    };

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final entry = stats.entries.elementAt(index);
          return Card(
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${entry.value}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(entry.key, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsStatsCards() {
    final totalEarned = _transactions.where((t) => t.type == TransactionType.earn).fold<int>(0, (sum, t) => sum + t.amount);
    final totalSpent = _transactions.where((t) => t.type == TransactionType.spend).fold<int>(0, (sum, t) => sum + t.amount);
    final stats = {
      'Transacciones': _transactions.length,
      'Ganados': '+$totalEarned',
      'Gastados': '-$totalSpent',
      'Balance': '${totalEarned - totalSpent}',
    };

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final entry = stats.entries.elementAt(index);
          Color? textColor;
          if (entry.key == 'Ganados') textColor = Colors.green;
          if (entry.key == 'Gastados') textColor = Colors.red;
          
          return Card(
            child: Container(
              width: 130,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${entry.value}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: textColor)),
                  const SizedBox(height: 4),
                  Text(entry.key, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['all', 'admin', 'staff', 'exhibitor', 'artist', 'attendee'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filterRole == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _filterRole = filter);
              },
            ),
          );
        },
      ),
    );
  }

  String _getFilterLabel(String role) {
    switch (role) {
      case 'all':
        return 'Todos';
      case 'admin':
        return 'Admins';
      case 'staff':
        return 'Staff';
      case 'exhibitor':
        return 'Expositores';
      case 'artist':
        return 'Artistas';
      case 'attendee':
        return 'Asistentes';
      default:
        return role;
    }
  }

  Widget _buildUsersList() {
    final users = _filteredUsers;

    if (users.isEmpty) {
      return Center(
        child: Text(
          'No hay usuarios',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserListTile(
          user: user,
          onEdit: () => _showEditUserDialog(user),
          onDelete: () => _confirmDeleteUser(user),
        );
      },
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateUserDialog(
        onUserCreated: () {
          _loadUsers();
        },
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onUserUpdated: () {
          _loadUsers();
        },
      ),
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text(
          '¿Estás seguro de eliminar a ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.deleteUser(user.id);
                _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario eliminado')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => DataManagementDialog(),
    );
  }
}

class UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserListTile({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(user.displayName[0].toUpperCase())
              : null,
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email ?? 'Sin email'),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                _getRoleLabel(user.role),
                style: const TextStyle(fontSize: 12),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.exhibitor:
        return 'Expositor';
      case UserRole.artist:
        return 'Artista';
      case UserRole.attendee:
        return 'Asistente';
    }
  }
}

class CreateUserDialog extends StatefulWidget {
  final VoidCallback onUserCreated;

  const CreateUserDialog({super.key, required this.onUserCreated});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.attendee;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Usuario'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Ingresa un email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) => (v?.isEmpty ?? true) || v!.length < 6
                    ? 'Mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: UserRole.values
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(_getRoleLabel(role)),
                        ))
                    .toList(),
                onChanged: (role) {
                  if (role != null) {
                    setState(() => _selectedRole = role);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      await userService.createUserByAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado exitosamente')),
        );
        widget.onUserCreated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.exhibitor:
        return 'Expositor';
      case UserRole.artist:
        return 'Artista';
      case UserRole.attendee:
        return 'Asistente';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUserUpdated;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late UserRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Usuario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Ingresa un nombre' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.badge),
              ),
              items: UserRole.values
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(_getRoleLabel(role)),
                      ))
                  .toList(),
              onChanged: (role) {
                if (role != null) {
                  setState(() => _selectedRole = role);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateUser,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      await userService.updateUserByAdmin(
        userId: widget.user.id,
        username: _usernameController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado')),
        );
        widget.onUserUpdated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.exhibitor:
        return 'Expositor';
      case UserRole.artist:
        return 'Artista';
      case UserRole.attendee:
        return 'Asistente';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}

class DataManagementDialog extends StatefulWidget {
  const DataManagementDialog({super.key});

  @override
  State<DataManagementDialog> createState() => _DataManagementDialogState();
}

class _DataManagementDialogState extends State<DataManagementDialog> {
  final SeedService _seedService = SeedService();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _seedData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Generando datos de prueba...';
    });

    try {
      await _seedService.seedAllData();
      
      // Force refresh events from Supabase to clear cache
      final eventService = EventService();
      await eventService.getEvents(forceRefresh: true);
      
      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Datos generados exitosamente';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base de datos poblada con datos de prueba. Recarga la app para ver los cambios.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de eliminar TODOS los eventos y productos?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Eliminando datos...';
    });

    try {
      await _seedService.clearAllData();
      
      // Force refresh events from Supabase to clear cache
      final eventService = EventService();
      await eventService.getEvents(forceRefresh: true);
      
      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Datos eliminados';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos eliminados correctamente. Recarga la app para ver los cambios.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Gestión de Datos'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generar datos de prueba para eventos, productos y concursantes del Comic Fest.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text('Generar Datos de Prueba'),
                subtitle: const Text('16 eventos + 12 productos + 8 concursantes'),
                trailing: _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.arrow_forward),
                onTap: _isLoading ? null : _seedData,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Eliminar Todos los Datos'),
                subtitle: const Text('Vaciar eventos, productos y concursantes'),
                trailing: _isLoading
                    ? null
                    : const Icon(Icons.arrow_forward),
                onTap: _isLoading ? null : _clearData,
              ),
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
