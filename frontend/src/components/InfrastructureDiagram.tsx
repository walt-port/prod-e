import React, { useCallback } from 'react';
import ReactFlow, {
  addEdge,
  Background,
  Connection,
  Controls,
  Edge,
  MarkerType,
  Node,
  useEdgesState,
  useNodesState,
} from 'reactflow';

import 'reactflow/dist/style.css';

// --- Node Definitions ---
const nodeStyle = {
  // Common style for reuse
  background: '#1f2335',
  color: '#c0caf5',
  border: '1px solid #9ece6a',
  fontFamily: 'Hermit, monospace',
  fontSize: '0.8rem',
};
const initialNodes: Node[] = [
  {
    id: 'internet',
    position: { x: 350, y: 25 }, // Centered top
    data: { label: 'Internet / User' },
    style: nodeStyle,
  },
  {
    id: 'alb',
    position: { x: 350, y: 125 }, // Below internet
    data: { label: 'prod-e-alb' },
    style: nodeStyle,
  },
  // Row of ECS Services
  {
    id: 'ecs-app',
    position: { x: 50, y: 225 }, // Top-left service
    data: { label: 'prod-e-app' },
    style: nodeStyle,
  },
  {
    id: 'ecs-backend',
    position: { x: 250, y: 225 }, // Top-middle service
    data: { label: 'prod-e-backend' },
    style: nodeStyle,
  },
  {
    id: 'ecs-grafana',
    position: { x: 450, y: 225 }, // Top-right service
    data: { label: 'prod-e-grafana' },
    style: nodeStyle,
  },
  {
    id: 'ecs-prometheus',
    position: { x: 650, y: 325 }, // Below Grafana
    data: { label: 'prod-e-prometheus' },
    style: nodeStyle,
  },
  // Database
  {
    id: 'rds',
    position: { x: 250, y: 325 }, // Below backend service
    data: { label: 'prod-e-db' },
    style: nodeStyle,
  },
];

// --- Edge Definitions ---
const edgeStyle = {
  // Common style for reuse
  stroke: '#7aa2f7',
};
const dbEdgeStyle = {
  stroke: '#bb9af7',
};
const monitoringEdgeStyle = {
  stroke: '#e0af68', // Orange for monitoring connections
};

const initialEdges: Edge[] = [
  {
    id: 'e-internet-alb',
    source: 'internet',
    target: 'alb',
    markerEnd: { type: MarkerType.ArrowClosed, color: edgeStyle.stroke },
    style: edgeStyle,
    animated: true,
  },
  {
    id: 'e-alb-app',
    source: 'alb',
    target: 'ecs-app',
    markerEnd: { type: MarkerType.ArrowClosed, color: edgeStyle.stroke },
    style: edgeStyle,
    animated: true,
  },
  {
    id: 'e-alb-backend',
    source: 'alb',
    target: 'ecs-backend',
    markerEnd: { type: MarkerType.ArrowClosed, color: edgeStyle.stroke },
    style: edgeStyle,
    animated: true,
  },
  {
    id: 'e-alb-grafana',
    source: 'alb',
    target: 'ecs-grafana',
    markerEnd: { type: MarkerType.ArrowClosed, color: edgeStyle.stroke },
    style: edgeStyle,
    animated: true,
  },
  {
    id: 'e-backend-rds',
    source: 'ecs-backend',
    target: 'rds',
    markerEnd: { type: MarkerType.ArrowClosed, color: dbEdgeStyle.stroke },
    style: dbEdgeStyle,
    animated: true,
  },
  {
    id: 'e-grafana-prometheus',
    source: 'ecs-grafana',
    target: 'ecs-prometheus',
    markerEnd: { type: MarkerType.ArrowClosed, color: monitoringEdgeStyle.stroke },
    style: monitoringEdgeStyle,
    animated: true,
  },
];

const InfrastructureDiagram: React.FC = () => {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

  // Handler for edge connections (optional for now)
  const onConnect = useCallback(
    (params: Connection | Edge) => setEdges(eds => addEdge(params, eds)),
    [setEdges]
  );

  return (
    <div style={{ width: '100%', height: '100%' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        fitView // Zoom to fit initially
        // ProOptions could hide attribution if needed later
        // proOptions={{ hideAttribution: true }}
      >
        <Controls />
        <Background color="#414868" gap={16} />
      </ReactFlow>
    </div>
  );
};

export default InfrastructureDiagram;
