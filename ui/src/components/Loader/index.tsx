import React from 'react';

const Loader: React.FC = () => {
    return (
        <div className="flex items-center justify-center self-center">
            <div className="flex items-end">
                {[
                    'bg-emerald-200',
                    'bg-emerald-300',
                    'bg-emerald-400',
                    'bg-emerald-500',
                    'bg-emerald-600'
                ].map((color, index) => (
                    <div
                        key={index}
                        className={`w-2 h-28 mx-1 rounded ${color} animate-loader`}
                        style={{ animationDelay: `${index * 0.1}s` }}
                    ></div>
                ))}
            </div>
        </div>
    );
};

export default Loader;
