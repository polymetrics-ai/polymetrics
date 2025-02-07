import * as React from 'react'
import { Separator } from '@/components/ui/separator'
import ConnectorIdentified from '@/components/data-agent/ConnectorIdentified'
import ConnectorConfiguration from '@/components/data-agent/ConnectorConfiguration'
import SyncInitiated from '@/components/data-agent/SyncInitiated'
import QueryBlock from '@/components/data-agent/QueryBlock'
import DataPresented from '@/components/data-agent/DataPresented'
import { Stepper } from '@stepperize/react'
import { dataAgentSteps } from '@/constants/constants'
import ConnectionCreated from '@/components/data-agent/ConnectionCreated'
import SyncInitialized from '@/components/data-agent/SyncInitialized'
import QueryResults from '@/components/data-agent/QueryResults'
import { PipelineData } from '@/types/pipeline'

type Mutable<T> = T extends readonly (infer U)[] ? U[] : T

interface PipelineStepperProps {
  stepper: Stepper<Mutable<typeof dataAgentSteps>>;
  pipelineData?: PipelineData;
}

export const PipelineStepper: React.FC<PipelineStepperProps> = ({ stepper, pipelineData }) => {
  const actionStepMap = {
    'connector_selection': 'connector-selected',
    'connection_creation': 'connection-created',
    'sync_initialization': 'sync-initialized',
    'query_execution': 'query-generated'
  };

  const filteredSteps = stepper.all.filter(step => 
    Object.values(actionStepMap).includes(step.id) && 
    pipelineData?.actions?.some(action => 
      action.action_type === Object.keys(actionStepMap).find(key => actionStepMap[key] === step.id)
    )
  );

  return (
    <div className="flex justify-start">
      <div className="flex-1 min-h-[400px] max-w-2xl">
        <div className="flex justify-start mb-4">
          <h3 className="text-base font-medium text-slate-800">Pipeline</h3>
        </div>
        <nav aria-label="Pipeline Steps" className="group">
          <ol className="flex flex-col" aria-orientation="vertical">
            {filteredSteps.map((step, index, array) => (
              <React.Fragment key={step.id}>
                <li className="flex items-start gap-4">
                  <div className="flex flex-col items-center">
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                      stepper.current.id === step.id ? 'bg-white border-2 border-emerald-500' : 
                      index < filteredSteps.indexOf(stepper.current) ? 'bg-emerald-500 text-white' : 
                      'bg-white border-2 border-slate-300'
                    }`}>
                      {/* Original icons from index.lazy.tsx */}
                      {step.id === 'connector-selected' && (
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" 
                          stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M12 22v-5" />
                          <path d="M9 7V2" />
                          <path d="M15 7V2" />
                          <path d="M6 13V8h12v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4Z" />
                        </svg>
                      )}
                      {step.id === 'connection-created' && (
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" 
                          stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M2 12h5" />
                          <path d="M17 12h5" />
                          <path d="M7 12a5 5 0 0 1 5-5h0a5 5 0 0 1 5 5h0a5 5 0 0 1-5 5h0a5 5 0 0 1-5-5Z" />
                        </svg>
                      )}
                      {step.id === 'sync-initialized' && (
                        <svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M1.90321 7.29677C1.90321 10.341 4.11041 12.4147 6.58893 12.8439C6.87255 12.893 7.06266 13.1627 7.01355 13.4464C6.96444 13.73 6.69471 13.9201 6.41109 13.871C3.49942 13.3668 0.86084 10.9127 0.86084 7.29677C0.860839 5.76009 1.55996 4.55245 2.37639 3.63377C2.96124 2.97568 3.63034 2.44135 4.16846 2.03202L2.53205 2.03202C2.25591 2.03202 2.03205 1.80816 2.03205 1.53202C2.03205 1.25588 2.25591 1.03202 2.53205 1.03202L5.53205 1.03202C5.80819 1.03202 6.03205 1.25588 6.03205 1.53202L6.03205 4.53202C6.03205 4.80816 5.80819 5.03202 5.53205 5.03202C5.25591 5.03202 5.03205 4.80816 5.03205 4.53202L5.03205 2.68645L5.03054 2.68759L5.03045 2.68766L5.03044 2.68767L5.03043 2.68767C4.45896 3.11868 3.76059 3.64538 3.15554 4.3262C2.44102 5.13021 1.90321 6.10154 1.90321 7.29677ZM13.0109 7.70321C13.0109 4.69115 10.8505 2.6296 8.40384 2.17029C8.12093 2.11718 7.93465 1.84479 7.98776 1.56188C8.04087 1.27898 8.31326 1.0927 8.59616 1.14581C11.4704 1.68541 14.0532 4.12605 14.0532 7.70321C14.0532 9.23988 13.3541 10.4475 12.5377 11.3662C11.9528 12.0243 11.2837 12.5586 10.7456 12.968L12.3821 12.968C12.6582 12.968 12.8821 13.1918 12.8821 13.468C12.8821 13.7441 12.6582 13.968 12.3821 13.968L9.38205 13.968C9.10591 13.968 8.88205 13.7441 8.88205 13.468L8.88205 10.468C8.88205 10.1918 9.10591 9.96796 9.38205 9.96796C9.65819 9.96796 9.88205 10.1918 9.88205 10.468L9.88205 12.3135L9.88362 12.3123C10.4551 11.8813 11.1535 11.3546 11.7585 10.6738C12.4731 9.86976 13.0109 8.89844 13.0109 7.70321Z" fill="currentColor" fillRule="evenodd" clipRule="evenodd"></path>
                        </svg>
                      )}
                      {step.id === 'query-generated' && (
                        <svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M10 6.5C10 8.433 8.433 10 6.5 10C4.567 10 3 8.433 3 6.5C3 4.567 4.567 3 6.5 3C8.433 3 10 4.567 10 6.5ZM9.30884 10.0159C8.53901 10.6318 7.56251 11 6.5 11C4.01472 11 2 8.98528 2 6.5C2 4.01472 4.01472 2 6.5 2C8.98528 2 11 4.01472 11 6.5C11 7.56251 10.6318 8.53901 10.0159 9.30884L12.8536 12.1464C13.0488 12.3417 13.0488 12.6583 12.8536 12.8536C12.6583 13.0488 12.3417 13.0488 12.1464 12.8536L9.30884 10.0159Z" fill="currentColor" fillRule="evenodd" clipRule="evenodd"></path>
                        </svg>
                      )}
                      {step.id === 'query-executed' && (
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" 
                          stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M3 3h18v18H3z"/>
                          <path d="M3 9h18"/>
                          <path d="M3 15h18"/>
                          <path d="M9 3v18"/>
                          <path d="M15 3v18"/>
                        </svg>
                      )}
                    </div>
                    {index < array.length - 1 && (
                      <Separator 
                        orientation="vertical" 
                        className={`h-full w-[2px] ${
                          index < filteredSteps.indexOf(stepper.current) ? 'bg-emerald-500' : 'bg-slate-200'
                        }`}
                        style={{
                          marginTop: '8px',
                          marginBottom: '-8px',
                          height: step.id === 'connection-created' ? '120px' :
                                 step.id === 'sync-initialized' ? '140px' :
                                 '100px'
                        }}
                      />
                    )}
                  </div>
                  <div className="flex-1 pt-1 pb-8">
                    <h3 className="text-base font-medium text-slate-800 mb-2">{step.title}</h3>
                    <p className="text-sm text-slate-500 mb-6">{step.description}</p>
                    {step.id === 'connector-selected' && (
                      <ConnectorIdentified 
                        connectors={pipelineData?.actions
                          ?.find(a => a.action_type === 'connector_selection')
                          ?.data.connectors}
                      />
                    )}
                    {step.id === 'connection-created' && (
                      <ConnectionCreated
                        source={pipelineData?.actions
                          ?.find(a => a.action_type === 'connection_creation')
                          ?.data.source}
                        destination={pipelineData?.actions
                          ?.find(a => a.action_type === 'connection_creation')
                          ?.data.destination}
                        streams={pipelineData?.actions
                          ?.find(a => a.action_type === 'connection_creation')
                          ?.data.streams}
                      />
                    )}
                    {step.id === 'sync-initialized' && (
                      <SyncInitiated
                        syncs={pipelineData?.actions
                          ?.find(a => a.action_type === 'sync_initialization')
                          ?.data.syncs}
                      />
                    )}
                    {step.id === 'query-generated' && (
                      <QueryBlock 
                        query={{
                          sql: pipelineData?.actions
                            ?.find(a => a.action_type === 'query_execution')
                            ?.data.query,
                          explanation: pipelineData?.actions
                            ?.find(a => a.action_type === 'query_execution')
                            ?.data.explanation
                        }}
                      />
                    )}
                    {step.id === 'query-executed' && <DataPresented />}
                  </div>
                </li>
              </React.Fragment>
            ))}
          </ol>
        </nav>
      </div>
    </div>
  )
} 