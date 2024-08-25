## Features

- **Multi-Source Data Extraction**: Connect to various data sources, including APIs (GitHub, Salesforce) and databases.
- **Seamless Connection Management**: Easily set up and manage connections to different data sources.
- **Automated Synchronization**: Background jobs handle data syncing from sources to the analytical database (DuckDB).
- **Interactive Data Visualization**: Create custom charts and dashboards using the synced data.
- **Flexible Dashboard Layout**: Utilize drag-and-drop interface for resizable and arrangeable dashboard components.

## Creating Charts

1. Navigate to the Charts page.
2. Enter a Chart Name and Description.
3. Select a Connector (data source) from the dropdown.
4. Choose a Visual Type:
   - Table
   - Bar
   - Line
   - Pie
   - Number
   - Area
5. Write your SQL query in the provided text area.
6. Click "Run Query" to preview the results.
7. Adjust settings as needed and click "Save".

## Building Dashboards

1. Go to the Dashboard page.
2. Click "Add Chart" to include your created charts.
3. Select the desired chart from the dropdown menu.
4. The chart will be added to your dashboard.
5. Use the drag-and-drop interface to arrange and resize charts as needed.
6. Click "Save" to preserve your dashboard layout.

## Data Synchronization

1. On the Connections page, locate the desired connector.
2. Click "Sync Now" to initiate the data synchronization process.
3. Review the confirmation dialog:
   - Source (e.g., GitHub)
   - Destination (e.g., DuckDB)
   - ETL process description
4. Click "Continue" to proceed with the synchronization.

### Synchronization Status

1. On the Connections page, click "View Details" for a specific connection.
2. The Data Synchronization Status dialog shows:
   - Stream Name (e.g., Commit, Branch, SHA)
   - Status (Active, Pending, Error)
   - Last Synced date
3. You can cancel or stop the sync process from this dialog.

## Note

- The synchronization process may take several minutes to complete.
- The analytics database may be temporarily unavailable during sync.
- Ongoing analytics queries may be interrupted during the sync process.

## Contributing

We welcome contributions to Polymetrics! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for details on how to get involved.

## License

This project is licensed under the Elastic License - see the [LICENSE.md](LICENSE.md) file for details.

## Support

If you encounter any issues or have questions, please file an issue on our GitHub repository or contact our support team at support@polymetrics.ai