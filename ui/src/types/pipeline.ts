export interface PipelineAction {
  action_type: string;
  data: Record<string, any>; // Or more specific if you have defined shapes
}

export interface PipelineData {
  connector_selection?: {
    source: Connector;
    destination: Connector;
  };
  connection_creation?: {
    config: Record<string, any>;
    validated_at: string;
  };
  sync_initialization?: {
    progress: number;
    records_transferred: number;
  };
  query_execution?: {
    sql: string;
    parameters: Record<string, any>;
  };
  query_generation?: {
    result_count: number;
    execution_time: number;
  };
  actions?: PipelineAction[];
} 