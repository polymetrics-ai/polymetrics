import React from 'react'
import ConnectorType from '../ConnectorType'

export interface ConnectorCardProps{
    name: string
    icon: string
}

const ConnectorCard:React.FC<ConnectorCardProps> = ({name , icon}) => { 
    return(
        <div className="flex flex-1 gap-2.5 overflow-hidden shrink items-center self-stretch p-4 border border-solid basis-0 bg-white border-slate-300 min-h-[80px] min-w-[240px] shadow-[0px_3px_8px_-2px_rgba(203,213,225,0.60)]">
                <div className="w-12 h-12 rounded-full border border-slate-200 bg-white flex items-center justify-center">
                    <img className="w-6 h-6" src={icon} />
                </div>
                {name && <div className="flex text-base items-center text-gray-500 text-ellipsis overflow-hidden whitespace-nowrap">{name}</div>}
        </div>
    )
}


export default ConnectorCard;