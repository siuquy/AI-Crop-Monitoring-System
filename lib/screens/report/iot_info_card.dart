import 'package:acmms/models/iot_data.dart';
import 'package:acmms/models/iot_device.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/service/bed_service.dart';
import '../../core/service/api_client.dart';

class IotInfoCard extends StatefulWidget {
  final String? bedId;

  const IotInfoCard({super.key, required this.bedId});

  @override
  State<IotInfoCard> createState() => _IotInfoCardState();
}

class _IotInfoCardState extends State<IotInfoCard> {
  bool _isLoading = true;
  IotData? _latestData;
  IotDevice? _device;
  String? _error;
  String? _bedName;

  @override
  void initState() {
    super.initState();
    _fetchIotData();
  }

  Future<void> _fetchIotData() async {
    if (widget.bedId == null || widget.bedId!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final bedMap = await BedService.getBedMap();

      // 1. Tìm tên luống
      final bedInfo = bedMap[widget.bedId];
      if (bedInfo != null) {
        _bedName = bedInfo['bedName']?.toString();
      }

      // 2. Tìm thiết bị và dữ liệu IoT thông qua API IotDevices theo BedId
      final deviceRes =
          await ApiClient.instance.get('/api/IotDevices?bedId=${widget.bedId}');
      if (deviceRes != null &&
          deviceRes['success'] == true &&
          deviceRes['data'] != null) {
        final data = deviceRes['data'];
        if (data is List && data.isNotEmpty) {
          _device = IotDevice.fromJson(data.first as Map<String, dynamic>);
        } else if (data is Map<String, dynamic>) {
          _device = IotDevice.fromJson(data);
        }

        if (_device != null && _device!.deviceId.isNotEmpty) {
          final dataRes = await ApiClient.instance
              .get('/api/IotDatas?deviceId=${_device!.deviceId}');
          if (dataRes != null &&
              dataRes['success'] == true &&
              dataRes['data'] != null) {
            final dData = dataRes['data'];
            List<IotData> parsedDatas = [];
            if (dData is List) {
              parsedDatas = dData
                  .map((d) => IotData.fromJson(d as Map<String, dynamic>))
                  .toList();
            } else if (dData is Map<String, dynamic>) {
              parsedDatas = [IotData.fromJson(dData)];
            }
            if (parsedDatas.isNotEmpty) {
              parsedDatas.sort((a, b) => (b.recordedAt ?? DateTime(0))
                  .compareTo(a.recordedAt ?? DateTime(0)));
              _latestData = parsedDatas.first;
            }
          }
        }
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404) {
        debugPrint('Lỗi API khi tải dữ liệu cho IotInfoCard: $e');
      }
      _error = null;
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu cho IotInfoCard: $e');
      _error = null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bedId == null) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(_error!,
            style: const TextStyle(
                color: Colors.red, fontStyle: FontStyle.italic)),
      );
    }

    if (_latestData == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Không có dữ liệu môi trường (IoT) cho khu vực này.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.shade50, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sensors_rounded,
                      color: Colors.blue.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      _bedName != null
                          ? 'Môi trường - $_bedName'
                          : 'Dữ liệu môi trường (IoT)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildIotMetric(Icons.thermostat,
                    '${_latestData!.temperature}°C', 'Nhiệt độ', Colors.orange),
                _buildIotMetric(Icons.water_drop, '${_latestData!.humidity}%',
                    'Độ ẩm', Colors.blue),
                _buildIotMetric(Icons.grass, '${_latestData!.soilMoisture}%',
                    'Ẩm đất', Colors.brown),
                _buildIotMetric(Icons.light_mode, '${_latestData!.light}',
                    'Ánh sáng', Colors.amber.shade600),
              ],
            ),
            if (_device != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_device!.name} • ${_latestData!.recordedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(_latestData!.recordedAt!.toLocal()) : 'N/A'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildIotMetric(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color.withOpacity(0.9))),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.6)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
