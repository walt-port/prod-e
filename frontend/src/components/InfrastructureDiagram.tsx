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
import DatabaseNode from './diagram_nodes/DatabaseNode'; // Import
import LoadBalancerNode from './diagram_nodes/LoadBalancerNode'; // Import
import ServiceNode from './diagram_nodes/ServiceNode'; // Import custom node
import UserNode from './diagram_nodes/UserNode'; // Import

// Define node types
const nodeTypes = {
  service: ServiceNode,
  user: UserNode, // Register
  loadbalancer: LoadBalancerNode, // Register
  database: DatabaseNode, // Register
  // Add other custom node types here later (e.g., database, loadbalancer)
};

// --- Node Definitions ---
const nodeStyle = {
  // Common style for reuse - Keep for nodes without custom components for now
  background: '#1f2335',
  color: '#c0caf5',
  border: '1px solid #9ece6a',
  fontFamily: 'Hermit, monospace',
  fontSize: '0.8rem',
};
const initialNodes: Node[] = [
  {
    id: 'internet',
    type: 'user', // Use custom type
    position: { x: 350, y: 25 }, // Centered top
    data: { label: 'Internet / User' },
  },
  {
    id: 'alb',
    type: 'loadbalancer', // Use custom type
    position: { x: 350, y: 125 }, // Below internet
    data: { label: 'prod-e-alb' },
  },
  // Row of ECS Services - Use custom type
  {
    id: 'ecs-app',
    type: 'service', // Use custom node type
    position: { x: 50, y: 225 }, // Top-left service
    data: { label: 'prod-e-app' },
  },
  {
    id: 'ecs-backend',
    type: 'service', // Use custom node type
    position: { x: 250, y: 225 }, // Top-middle service
    data: { label: 'prod-e-backend' },
  },
  {
    id: 'ecs-grafana',
    type: 'service', // Use custom node type
    position: { x: 450, y: 225 }, // Top-right service
    data: { label: 'prod-e-grafana' },
  },
  {
    id: 'ecs-prometheus',
    type: 'service', // Use custom node type
    position: { x: 650, y: 325 }, // Below Grafana
    data: { label: 'prod-e-prometheus' },
  },
  // Database
  {
    id: 'rds',
    type: 'database', // Use custom type
    position: { x: 250, y: 325 }, // Below backend service
    data: { label: 'prod-e-db' },
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
        nodeTypes={nodeTypes} // Pass custom node types
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
