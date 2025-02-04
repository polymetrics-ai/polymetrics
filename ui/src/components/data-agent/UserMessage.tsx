import { FC } from 'react'

interface UserMessageProps {
  query: string
}

export const UserMessage: FC<UserMessageProps> = ({ query }) => (
  <div className="flex justify-end mb-8">
    <div className="flex flex-col items-end">
      <div className="bg-emerald-700 shadow-sm p-6 rounded-none max-w-2xl">
        <p className="text-white font-medium">{query || "How many users have starred our github repo"}</p>
      </div>
      <span className="text-xs text-slate-500 mt-2 mr-2">You</span>
    </div>
  </div>
) 