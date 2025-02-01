import { Highlight, themes } from 'prism-react-renderer';

export default function QueryBlock() {
    const sqlQuery = `SELECT COUNT(DISTINCT user_id) as star_count FROM github_events WHERE repo_name = 'your-org/your-repo' AND event_type = 'WatchEvent' AND created_at >= NOW() - INTERVAL '30 days';`;

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
        </div>
    );
} 