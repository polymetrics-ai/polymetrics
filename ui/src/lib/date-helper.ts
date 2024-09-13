import dayjs from 'dayjs';

export const getTimeStamp = (updatedAt: string): string => {
    console.log('updatedAt', updatedAt, dayjs(updatedAt).format('D MMMM YYYY'));

    return dayjs(updatedAt).format('D MMMM YYYY');
};
