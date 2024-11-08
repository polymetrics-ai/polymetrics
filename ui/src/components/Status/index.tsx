import React from 'react';

export interface StatusProps {
    isConnected: boolean;
}

const Status: React.FC<StatusProps> = ({ isConnected }) => {
    console.log("connectred",isConnected)
    return (
        <div
            className={`w-2.5 h-2.5 rounded-full ${isConnected ? `bg-green-500` : `bg-red-500`}`}
        ></div>
    );
};

export default Status;
