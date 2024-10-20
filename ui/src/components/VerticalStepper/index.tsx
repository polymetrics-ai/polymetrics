import React from 'react';
import { connectorSteps } from '@/constants/constants';
import { Button, Separator } from '../ui';

export interface StepperProps {
    stepper: {
      all: Array<{id: string, title: string, description: string}>;
      current: { id: string, index: number };
      goTo: (id: string) => void;
    };
  }

const VerticalStepper: React.FC<StepperProps> = ({ stepper }) => {
    return (
        <nav aria-label="Checkout Steps" className="group my-4">
            <div className="flex flex-col flex-grow self-start">
                {stepper.all.map((step, index) => (
                    <React.Fragment key={step.id}>
                        <div className="flex items-start">
                            <div className="flex flex-col items-center">
                                <Button
                                    type="button"
                                    role="tab"
                                    variant={index <= stepper.current.index ? 'default' : 'outline'}
                                    aria-current={
                                        stepper.current.id === step.id ? 'step' : undefined
                                    }
                                    aria-posinset={index + 1}
                                    aria-setsize={stepper.all.length}
                                    aria-selected={stepper.current.id === step.id}
                                    className={`flex w-7 h-7 p-0 items-center justify-center rounded-full ${index === stepper.current.index ? 'bg-white hover:bg-white border-2 border-emerald-600' : index < stepper.current.index ? '' : 'hover:bg-white border-2 border-slate-200'}`}
                                    onClick={() => stepper.goTo(step.id)}
                                >
                                    {index < stepper.current.index ? (
                                        <img
                                            src={'/icon-tick.svg'}
                                            alt="Completed"
                                            className="w-3.5 h-3.5"
                                        />
                                    ) : (
                                        <span
                                            className={`text-sm font-semibold  ${index === stepper.current.index ? 'text-emerald-600' : index < stepper.current.index ? '' : 'text-slate-400'}`}
                                        >
                                            {index + 1}
                                        </span>
                                    )}
                                </Button>
                                {index < stepper.all.length - 1 && (
                                    <Separator
                                        className={`h-16 bg-white border border-dashed border-slate-300`}
                                        orientation="vertical"
                                    />
                                )}
                            </div>
                            <div className="flex flex-col justify-center ml-2">
                                <span
                                    className={`text-base font-normal ${index === stepper.current.index ? 'text-slate-800' : 'text-slate-500'}`}
                                >
                                    {step.title}
                                </span>
                                <span className="text-sm font-normal text-slate-400">
                                    {step.description}
                                </span>
                            </div>
                        </div>
                    </React.Fragment>
                ))}
            </div>
        </nav>
    );
};

export default VerticalStepper;
