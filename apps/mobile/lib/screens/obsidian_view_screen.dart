import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/muji_theme.dart';

class ObsidianViewScreen extends StatefulWidget {
  const ObsidianViewScreen({Key? key}) : super(key: key);

  @override
  State<ObsidianViewScreen> createState() => _ObsidianViewScreenState();
}

class _ObsidianViewScreenState extends State<ObsidianViewScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowController;
  
  final TransformationController _transformationController = TransformationController();
  
  // Sample data - replace with actual user topics/interests
  final List<TopicNode> _nodes = [
    TopicNode(
      id: '1',
      title: '인공지능',
      x: 0.5,
      y: 0.5,
      importance: 1.0,
      isInterested: true,
    ),
    TopicNode(
      id: '2',
      title: '머신러닝',
      x: 0.3,
      y: 0.4,
      importance: 0.8,
      isInterested: true,
    ),
    TopicNode(
      id: '3',
      title: '딥러닝',
      x: 0.7,
      y: 0.4,
      importance: 0.7,
      isInterested: false,
    ),
    TopicNode(
      id: '4',
      title: '자연어처리',
      x: 0.4,
      y: 0.6,
      importance: 0.6,
      isInterested: true,
    ),
    TopicNode(
      id: '5',
      title: '컴퓨터 비전',
      x: 0.6,
      y: 0.6,
      importance: 0.5,
      isInterested: false,
    ),
    TopicNode(
      id: '6',
      title: '데이터 사이언스',
      x: 0.2,
      y: 0.5,
      importance: 0.6,
      isInterested: false,
    ),
    TopicNode(
      id: '7',
      title: '블록체인',
      x: 0.8,
      y: 0.5,
      importance: 0.4,
      isInterested: false,
    ),
  ];
  
  final List<NodeConnection> _connections = [
    NodeConnection(fromId: '1', toId: '2', strength: 0.9),
    NodeConnection(fromId: '1', toId: '3', strength: 0.8),
    NodeConnection(fromId: '2', toId: '3', strength: 0.7),
    NodeConnection(fromId: '1', toId: '4', strength: 0.6),
    NodeConnection(fromId: '1', toId: '5', strength: 0.5),
    NodeConnection(fromId: '2', toId: '6', strength: 0.6),
    NodeConnection(fromId: '3', toId: '5', strength: 0.7),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MujiTheme.bg,
      appBar: AppBar(
        backgroundColor: MujiTheme.bg,
        elevation: 0,
        title: Text(
          '관심 주제 그래프',
          style: MujiTheme.mobileH3.copyWith(color: MujiTheme.textBody),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: MujiTheme.textBody),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.info_circle, color: MujiTheme.textLight),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(100),
            child: Container(
              width: MediaQuery.of(context).size.width * 2,
              height: MediaQuery.of(context).size.height * 2,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GraphPainter(
                      nodes: _nodes,
                      connections: _connections,
                      animationValue: _animationController.value,
                      glowAnimation: _glowController,
                    ),
                    child: Stack(
                      children: _nodes.map((node) {
                        final screenSize = MediaQuery.of(context).size;
                        final x = node.x * screenSize.width * 2;
                        final y = node.y * screenSize.height * 2;
                        
                        return Positioned(
                          left: x - 40,
                          top: y - 40,
                          child: _buildNode(node),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }
  
  Widget _buildNode(TopicNode node) {
    final baseSize = 60.0 + (node.importance * 40.0);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showNodeDetails(node);
      },
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowIntensity = node.isInterested 
              ? _glowController.value * 0.5 + 0.5 
              : 0.0;
          
          return Container(
            width: baseSize,
            height: baseSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: node.isInterested 
                  ? MujiTheme.sage.withOpacity(0.8)
                  : MujiTheme.textHint,
              boxShadow: node.isInterested ? [
                BoxShadow(
                  color: MujiTheme.sage.withOpacity(glowIntensity * 0.6),
                  blurRadius: 20 * glowIntensity,
                  spreadRadius: 5 * glowIntensity,
                ),
                BoxShadow(
                  color: MujiTheme.sage.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: node.isInterested 
                    ? MujiTheme.sage 
                    : MujiTheme.textHint.withOpacity(0.3),
                width: node.isInterested ? 2 : 1,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  node.title,
                  style: MujiTheme.mobileCaption.copyWith(
                    color: node.isInterested ? Colors.white : MujiTheme.textBody,
                    fontWeight: node.isInterested ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLegend() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MujiTheme.bg.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MujiTheme.textHint.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MujiTheme.sage,
                    boxShadow: [
                      BoxShadow(
                        color: MujiTheme.sage.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '관심 주제',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: MujiTheme.textBody,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MujiTheme.textHint,
                    border: Border.all(
                      color: MujiTheme.textHint.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '일반 주제',
                  style: MujiTheme.mobileCaption.copyWith(
                    color: MujiTheme.textBody,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showNodeDetails(TopicNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MujiTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MujiTheme.textHint.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  node.title,
                  style: MujiTheme.mobileH3.copyWith(color: MujiTheme.textBody),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      node.isInterested ? CupertinoIcons.star_fill : CupertinoIcons.star,
                      color: node.isInterested ? MujiTheme.sage : MujiTheme.textLight,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      node.isInterested ? '관심 주제' : '일반 주제',
                      style: MujiTheme.mobileBody.copyWith(
                        color: MujiTheme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '중요도: ${(node.importance * 100).toInt()}%',
                  style: MujiTheme.mobileBody.copyWith(
                    color: MujiTheme.textLight,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: node.isInterested ? MujiTheme.textHint : MujiTheme.sage,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        node.isInterested = !node.isInterested;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      node.isInterested ? '관심 해제' : '관심 등록',
                      style: MujiTheme.mobileBody.copyWith(
                        color: node.isInterested ? MujiTheme.textBody : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MujiTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '그래프 사용 방법',
          style: MujiTheme.mobileH3.copyWith(color: MujiTheme.textBody),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• 핀치 제스처로 확대/축소',
              style: MujiTheme.mobileBody.copyWith(color: MujiTheme.textBody),
            ),
            const SizedBox(height: 8),
            Text(
              '• 드래그로 이동',
              style: MujiTheme.mobileBody.copyWith(color: MujiTheme.textBody),
            ),
            const SizedBox(height: 8),
            Text(
              '• 노드를 탭하여 상세 정보 확인',
              style: MujiTheme.mobileBody.copyWith(color: MujiTheme.textBody),
            ),
            const SizedBox(height: 8),
            Text(
              '• 빛나는 노드는 관심 주제',
              style: MujiTheme.mobileBody.copyWith(color: MujiTheme.textBody),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: MujiTheme.mobileBody.copyWith(
                color: MujiTheme.sage,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<TopicNode> nodes;
  final List<NodeConnection> connections;
  final double animationValue;
  final AnimationController glowAnimation;
  
  GraphPainter({
    required this.nodes,
    required this.connections,
    required this.animationValue,
    required this.glowAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections
    for (final connection in connections) {
      final fromNode = nodes.firstWhere((n) => n.id == connection.fromId);
      final toNode = nodes.firstWhere((n) => n.id == connection.toId);
      
      final fromX = fromNode.x * size.width;
      final fromY = fromNode.y * size.height;
      final toX = toNode.x * size.width;
      final toY = toNode.y * size.height;
      
      final paint = Paint()
        ..color = MujiTheme.textHint.withOpacity(connection.strength * 0.3)
        ..strokeWidth = connection.strength * 3
        ..style = PaintingStyle.stroke;
      
      // Animate connection with subtle wave effect
      final path = Path();
      path.moveTo(fromX, fromY);
      
      final controlX = (fromX + toX) / 2 + math.sin(animationValue * 2 * math.pi) * 20;
      final controlY = (fromY + toY) / 2 + math.cos(animationValue * 2 * math.pi) * 20;
      
      path.quadraticBezierTo(controlX, controlY, toX, toY);
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(GraphPainter oldDelegate) => true;
}

class TopicNode {
  final String id;
  final String title;
  final double x;
  final double y;
  final double importance;
  bool isInterested;
  
  TopicNode({
    required this.id,
    required this.title,
    required this.x,
    required this.y,
    required this.importance,
    required this.isInterested,
  });
}

class NodeConnection {
  final String fromId;
  final String toId;
  final double strength;
  
  NodeConnection({
    required this.fromId,
    required this.toId,
    required this.strength,
  });
}