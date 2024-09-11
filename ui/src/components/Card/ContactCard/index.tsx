import React from 'react';

export interface ConnectorCardProps {

}

const ContactCard: React.FC = () => {
    return (
        // px-4 pt-4 pb-3
        <div className="flex flex-col px-4 pt-4 pb-2 bg-emerald-50 border border-emerald-200 border-solid">
            <div className="flex gap-4 items-start w-full">
                <div className='w-14 h-14 p-2.5 bg-emerald-100 border border-emerald-200'>
                    <img className='object-contain' src='/icon-chat.svg' />
                </div>
                <div className="flex flex-col flex-1 shrink basis-0">
                    <div className="text-base font-medium tracking-normal text-slate-800">
                        Contact Support
                    </div>
                    <div className="text-sm tracking-tight leading-5 text-slate-500">
                        We’re here to help! Chat with us if you have any questions.
                    </div>
                </div>
            </div>
            <div className="flex gap-0.5 justify-center items-center mr-7 mt-1 text-sm font-semibold tracking-normal leading-5 text-emerald-500">
                <div className="self-stretch py-2 my-auto bg-white bg-opacity-0">
                    Chat with us
                </div>
                <img
                    loading="lazy"
                    src="https://cdn.builder.io/api/v1/image/assets/TEMP/cfb49d3e6a1808bf21e101ab7c0f23d51b11f3604f1bad360927bd0906c83d19?placeholderIfAbsent=true&apiKey=698d28bd40454379b0c73734472477dd"
                    className="object-contain shrink-0 self-stretch my-auto w-3.5 aspect-square"
                />
            </div>
        </div>
    );
};

export default ContactCard;
