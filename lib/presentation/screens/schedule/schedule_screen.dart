import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/agendamento.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/language_provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final ApiService _apiService = ApiService();

  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  String _selectedTipo = 'chamada_voz';
  String _selectedPrioridade = 'normal';

  List<Agendamento> _agendados = [];
  List<Agendamento> _historico = [];

  bool _isLoading = false;
  String? _errorMessage;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAgendamentos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAgendamentos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final idosoId = StorageService.getIdosoId();
      if (idosoId == null) throw Exception('ID not found');

      final data = await _apiService.listAgendamentos(idosoId);
      final all = data.map((json) => Agendamento.fromJson(json)).toList();

      setState(() {
        _agendados = all.where((a) => a.status == 'agendado').toList()
          ..sort((a, b) => a.dataHoraAgendada.compareTo(b.dataHoraAgendada));
        _historico = all.where((a) => a.status != 'agendado').toList()
          ..sort((a, b) => b.dataHoraAgendada.compareTo(a.dataHoraAgendada));
        _retryCount = 0;
      });
    } catch (e) {
      _logger.e('Erro ao carregar agendamentos: $e');
      setState(() {
        _errorMessage = 'error_load';
        _retryCount++;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9F70D8), Color(0xFFFFB6C1)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(lang),
                  _buildCalendarCard(lang),
                  _buildOptionsRow(lang),
                  const SizedBox(height: 12),
                  _buildScheduleButton(lang),
                  const SizedBox(height: 16),
                  Expanded(child: _buildAppointmentsTabs(lang)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
            onPressed: () => context.pop(),
          ),
          Text(
            lang.t('agenda'),
            style: AppTextStyles.elderlySubtitle.copyWith(color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
            onPressed: _isLoading ? null : _loadAgendamentos,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(LanguageProvider lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final validInitialDate = _selectedDate.isBefore(today) ? today : _selectedDate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 32),
                    onPressed: _canGoToPreviousMonth()
                        ? () => setState(() {
                              _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                            })
                        : null,
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'pt_BR').format(_displayedMonth),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 32),
                    onPressed: () => setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                    }),
                  ),
                ],
              ),
              SizedBox(
                height: 280,
                child: CalendarDatePicker(
                  initialDate: validInitialDate,
                  currentDate: today,
                  firstDate: today,
                  lastDate: today.add(const Duration(days: 365)),
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                      if (date.month != _displayedMonth.month || date.year != _displayedMonth.year) {
                        _displayedMonth = DateTime(date.year, date.month);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canGoToPreviousMonth() {
    final now = DateTime.now();
    return _displayedMonth.year > now.year ||
        (_displayedMonth.year == now.year && _displayedMonth.month > now.month);
  }

  Widget _buildOptionsRow(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF9F70D8)),
                      const SizedBox(height: 4),
                      Text(_selectedTime.format(context),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(lang.t('time'), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => _showTipoSelector(lang),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Icon(
                        _selectedTipo == 'chamada_video' ? Icons.videocam : Icons.phone,
                        color: const Color(0xFF9F70D8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTipo == 'chamada_video' ? lang.t('video') : lang.t('voice'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(lang.t('type'), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => _showPrioridadeSelector(lang),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Icon(Icons.flag, color: _getPrioridadeColor(_selectedPrioridade)),
                      const SizedBox(height: 4),
                      Text(
                        _getPrioridadeLabel(_selectedPrioridade, lang).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold,
                          color: _getPrioridadeColor(_selectedPrioridade),
                        ),
                      ),
                      Text(lang.t('priority'), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }

  void _showTipoSelector(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.t('call_type'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF9F70D8)),
              title: Text(lang.t('voice_call')),
              trailing: _selectedTipo == 'chamada_voz' ? const Icon(Icons.check, color: Color(0xFF9F70D8)) : null,
              onTap: () { setState(() => _selectedTipo = 'chamada_voz'); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Color(0xFF9F70D8)),
              title: Text(lang.t('video_call')),
              trailing: _selectedTipo == 'chamada_video' ? const Icon(Icons.check, color: Color(0xFF9F70D8)) : null,
              onTap: () { setState(() => _selectedTipo = 'chamada_video'); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrioridadeSelector(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.t('priority'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            for (final p in ['normal', 'alta', 'urgente'])
              ListTile(
                leading: Icon(Icons.flag, color: _getPrioridadeColor(p)),
                title: Text(_getPrioridadeLabel(p, lang)),
                trailing: _selectedPrioridade == p ? Icon(Icons.check, color: _getPrioridadeColor(p)) : null,
                onTap: () { setState(() => _selectedPrioridade = p); Navigator.pop(ctx); },
              ),
          ],
        ),
      ),
    );
  }

  String _getPrioridadeLabel(String p, LanguageProvider lang) {
    switch (p) {
      case 'urgente': return lang.t('urgent');
      case 'alta': return lang.t('high');
      default: return lang.t('normal');
    }
  }

  Color _getPrioridadeColor(String p) {
    switch (p) {
      case 'urgente': return Colors.red;
      case 'alta': return Colors.orange;
      default: return Colors.green;
    }
  }

  Widget _buildScheduleButton(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _scheduleCall(lang),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF9F70D8),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 4,
          ),
          child: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_selectedTipo == 'chamada_video' ? Icons.videocam : Icons.phone, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      lang.t('schedule'),
                      style: AppTextStyles.elderlyButton.copyWith(color: const Color(0xFF9F70D8)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsTabs(LanguageProvider lang) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF9F70D8),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF9F70D8),
            tabs: [
              Tab(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule, size: 18), const SizedBox(width: 4),
                  Text('${lang.t('scheduled')} (${_agendados.length})'),
                ],
              )),
              Tab(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 18), const SizedBox(width: 4),
                  Text('${lang.t('history')} (${_historico.length})'),
                ],
              )),
            ],
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(lang.t(_errorMessage!), style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadAgendamentos,
                    icon: const Icon(Icons.refresh),
                    label: Text('${lang.t('retry')} ($_retryCount)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentList(_agendados, isHistory: false, lang: lang),
                  _buildAppointmentList(_historico, isHistory: true, lang: lang),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(List<Agendamento> appointments, {required bool isHistory, required LanguageProvider lang}) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isHistory ? Icons.history : Icons.calendar_today, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                isHistory ? lang.t('no_history') : lang.t('no_scheduled'),
                style: AppTextStyles.elderlyBody.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (!isHistory) ...[
                const SizedBox(height: 12),
                Text(lang.t('use_calendar'), style: AppTextStyles.elderlyCaption, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAgendamentos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) => _buildAppointmentCard(appointments[index], isHistory: isHistory, lang: lang),
      ),
    );
  }

  Widget _buildAppointmentCard(Agendamento a, {required bool isHistory, required LanguageProvider lang}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(a.status).withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    a.tipo == 'chamada_video' ? Icons.videocam : Icons.phone,
                    color: _getStatusColor(a.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(a.dataHoraAgendada), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('HH:mm').format(a.dataHoraAgendada), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(a.status).withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(a.status, lang),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(a.status)),
                  ),
                ),
              ],
            ),
            if (a.prioridade != 'normal')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: _getPrioridadeColor(a.prioridade)),
                    const SizedBox(width: 4),
                    Text('${lang.t('priority_label')} ${_getPrioridadeLabel(a.prioridade, lang)}',
                        style: TextStyle(fontSize: 12, color: _getPrioridadeColor(a.prioridade))),
                  ],
                ),
              ),
            if (a.isOverdue && !isHistory)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(lang.t('overdue'), style: const TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isHistory) ...[
                  TextButton.icon(
                    onPressed: () => _showEditDialog(a, lang),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(lang.t('edit')),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmComplete(a, lang),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(lang.t('complete')),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(a, lang),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: Text(lang.t('cancel_schedule')),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'agendado': return const Color(0xFF9F70D8);
      case 'concluido': return Colors.green;
      case 'cancelado': return Colors.red;
      case 'em_andamento': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status, LanguageProvider lang) {
    switch (status) {
      case 'agendado': return lang.t('status_scheduled');
      case 'concluido': return lang.t('status_completed');
      case 'cancelado': return lang.t('status_cancelled');
      case 'em_andamento': return lang.t('status_in_progress');
      default: return status;
    }
  }

  Future<void> _showEditDialog(Agendamento a, LanguageProvider lang) async {
    DateTime editDate = a.dataHoraAgendada;
    TimeOfDay editTime = TimeOfDay(hour: a.dataHoraAgendada.hour, minute: a.dataHoraAgendada.minute);
    String editTipo = a.tipo;
    String editPrioridade = a.prioridade;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(lang.t('edit_schedule')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd/MM/yyyy').format(editDate)),
                  subtitle: Text(lang.t('date')),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx, initialDate: editDate,
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setDialogState(() => editDate = date);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(editTime.format(ctx)),
                  subtitle: Text(lang.t('time')),
                  onTap: () async {
                    final time = await showTimePicker(context: ctx, initialTime: editTime);
                    if (time != null) setDialogState(() => editTime = time);
                  },
                ),
                ListTile(
                  leading: Icon(editTipo == 'chamada_video' ? Icons.videocam : Icons.phone),
                  title: Text(editTipo == 'chamada_video' ? lang.t('video') : lang.t('voice')),
                  subtitle: Text(lang.t('call_type')),
                  onTap: () => setDialogState(() {
                    editTipo = editTipo == 'chamada_video' ? 'chamada_voz' : 'chamada_video';
                  }),
                ),
                ListTile(
                  leading: Icon(Icons.flag, color: _getPrioridadeColor(editPrioridade)),
                  title: Text(_getPrioridadeLabel(editPrioridade, lang).toUpperCase()),
                  subtitle: Text(lang.t('priority')),
                  onTap: () {
                    final opts = ['normal', 'alta', 'urgente'];
                    final i = (opts.indexOf(editPrioridade) + 1) % opts.length;
                    setDialogState(() => editPrioridade = opts[i]);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(lang.t('cancel'))),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9F70D8)),
              child: Text(lang.t('save')),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final dt = DateTime(editDate.year, editDate.month, editDate.day, editTime.hour, editTime.minute);
      setState(() => _isLoading = true);
      try {
        final ok = await _apiService.updateAgendamento(
          agendamentoId: a.id, dataHoraAgendada: dt, tipo: editTipo, prioridade: editPrioridade,
        );
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lang.t('updated')), backgroundColor: const Color(0xFF9F70D8)),
          );
        }
        await _loadAgendamentos();
      } catch (e) {
        _logger.e('Erro ao atualizar: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmComplete(Agendamento a, LanguageProvider lang) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('complete_title')),
        content: Text(lang.t('complete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(lang.t('no'))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(lang.t('yes_complete')),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        final success = await _apiService.updateAgendamentoStatus(agendamentoId: a.id, status: 'concluido');
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lang.t('completed_msg')), backgroundColor: Colors.green),
          );
        }
        await _loadAgendamentos();
      } catch (e) { _logger.e('Erro: $e'); }
      finally { setState(() => _isLoading = false); }
    }
  }

  Future<void> _confirmDelete(Agendamento a, LanguageProvider lang) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('cancel_title')),
        content: Text(lang.t('cancel_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(lang.t('no'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(lang.t('yes'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        final success = await _apiService.cancelAgendamento(a.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lang.t('cancelled_msg')), backgroundColor: Colors.orange),
          );
        }
        await _loadAgendamentos();
      } catch (e) { _logger.e('Erro: $e'); }
      finally { setState(() => _isLoading = false); }
    }
  }

  Future<void> _scheduleCall(LanguageProvider lang) async {
    final now = DateTime.now();
    final dateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    if (dateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('select_future'), style: const TextStyle(fontSize: 16)), backgroundColor: Colors.red),
      );
      return;
    }

    if (dateTime.isBefore(now.add(const Duration(minutes: 5)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('min_5_minutes'), style: const TextStyle(fontSize: 16)), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final idosoId = StorageService.getIdosoId();
      if (idosoId == null) throw Exception('ID not found');

      if (mounted) {
        showDialog(
          context: context, barrierDismissible: false,
          builder: (_) => Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(lang.t('creating')),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final result = await _apiService.createAgendamento(
        idosoId: idosoId, dataHoraAgendada: dateTime,
        tipo: _selectedTipo, prioridade: _selectedPrioridade,
      );

      if (mounted) Navigator.of(context).pop();

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lang.t('success_scheduled')), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
          );
        }
        await _loadAgendamentos();
      }
    } catch (e) {
      _logger.e('Erro ao agendar: $e');
      if (mounted) {
        try { Navigator.of(context).pop(); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lang.t('error_schedule')}: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
