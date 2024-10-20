import React, { useState } from 'react';
import { Input } from '@/components/ui/input';

interface SearchBarProps {
    placeholder: string;
    onSearch: (query: string) => void;
}

const SearchBar: React.FC<SearchBarProps> = ({ placeholder = 'Search...', onSearch }) => {
    const [query, setQuery] = useState('');

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSearch(query);
    };

    return (
        <form onSubmit={handleSubmit} className="w-full">
            <div className="relative">
                <img
                    className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400"
                    src="/icon-search.svg"
                />
                <Input
                    type="text"
                    placeholder={placeholder}
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    className="pl-10 pr-4"
                />
            </div>
        </form>
    );
};

export default SearchBar;
