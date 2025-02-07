import { FC } from 'react';
import { Highlight, themes } from 'prism-react-renderer';

interface QueryBlockProps {
    query?: {
        sql: string;
        explanation?: string;
    };
}

const QueryBlock: FC<QueryBlockProps> = ({ query }) => {
    const sqlQuery = query?.sql ?? `SELECT * FROM table;`;

    if (!sqlQuery) {
        return null;
    }

    return (
        <div className="mt-4">
            <Highlight
                theme={themes.nightOwl}
                code={sqlQuery}
                language="sql"
            >
                {({ className, style, tokens, getLineProps, getTokenProps }) => (
                    <pre className="p-4 bg-slate-900 rounded-lg whitespace-pre-wrap break-words">
                        {tokens.map((line, i) => (
                            <div key={i} {...getLineProps({ line })}>
                                {line.map((token, key) => (
                                    <span key={key} {...getTokenProps({ token })} />
                                ))}
                            </div>
                        ))}
                    </pre>
                )}
            </Highlight>
            {query?.explanation && (
                <p className="text-sm text-emerald-700 mt-2">{query.explanation}</p>
            )}
        </div>
    );
};

export default QueryBlock; 