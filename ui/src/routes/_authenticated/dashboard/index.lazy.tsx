import { createLazyFileRoute } from '@tanstack/react-router';

import {
    Bird,
    Book,
    Bot,
    Code2,
    CornerDownLeft,
    LifeBuoy,
    Mic,
    Paperclip,
    Rabbit,
    Settings,
    Settings2,
    Share,
    SquareTerminal,
    SquareUser,
    Triangle,
    Turtle
} from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui';
import { Button } from '@/components/ui/button';
import {
    Drawer,
    DrawerContent,
    DrawerDescription,
    DrawerHeader,
    DrawerTitle,
    DrawerTrigger
} from '@/components/ui/drawer';

import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue
} from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import LoginForm from '@/components/LoginForm';

export const Route = createLazyFileRoute('/_authenticated/dashboard/')({
    component: Dashboard
});

export function Dashboard() {
    return (
        // <div className="grid h-screen w-full pl-[70px]">
        //     <aside className="inset-y fixed  left-0 z-20 flex h-full flex-col border-r">
        //         <div className="border-b p-4">
        //             {/* <Button asChild size="icon" aria-label="Home"> */}
        //                 <img className='h-9 w-9' src="pm-logo.svg" />
        //             {/* </Button> */}
        //         </div>
        //         <nav className="grid gap-5 p-5">
        //             <TooltipProvider>
        //                 <Tooltip>
        //                     <TooltipTrigger asChild>
        //                         <Button
        //                             variant="ghost"
        //                             size="icon"
        //                             className="bg-muted hover:bg-emerald-100"
        //                             aria-label="Playground"
        //                         >
        //                            <img className='h-6 w-6 ' src="/connections-icon-active.svg" />
        //                         </Button>
        //                     </TooltipTrigger>
        //                     <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
        //                         Playground
        //                     </TooltipContent>
        //                 </Tooltip>
        //             </TooltipProvider>
        //             <TooltipProvider>
        //                 <Tooltip>
        //                     <TooltipTrigger asChild>
        //                         <Button
        //                             variant="ghost"
        //                             size="icon"
        //                             className="rounded-lg"
        //                             aria-label="Models"
        //                         >
        //                             <Bot className="size-5" />
        //                         </Button>
        //                     </TooltipTrigger>
        //                     <TooltipContent side="right" sideOffset={5}>
        //                         Models
        //                     </TooltipContent>
        //                 </Tooltip>
        //             </TooltipProvider>
        //             <TooltipProvider>
        //                 <Tooltip>
        //                     <TooltipTrigger asChild>
        //                         <Button
        //                             variant="ghost"
        //                             size="icon"
        //                             className="rounded-lg"
        //                             aria-label="API"
        //                         >
        //                             <Code2 className="size-5" />
        //                         </Button>
        //                     </TooltipTrigger>
        //                     <TooltipContent side="right" sideOffset={5}>
        //                         API
        //                     </TooltipContent>
        //                 </Tooltip>
        //             </TooltipProvider>
        //             <TooltipProvider>
        //                 <Tooltip>
        //                     <TooltipTrigger asChild>
        //                         <Button
        //                             variant="ghost"
        //                             size="icon"
        //                             className="rounded-lg"
        //                             aria-label="Documentation"
        //                         >
        //                             <Book className="size-5" />
        //                         </Button>
        //                     </TooltipTrigger>
        //                     <TooltipContent side="right" sideOffset={5}>
        //                         Documentation
        //                     </TooltipContent>
        //                 </Tooltip>
        //             </TooltipProvider>
        //             <TooltipProvider>
        //                 <Tooltip>
        //                     <TooltipTrigger asChild>
        //                         <Button
        //                             variant="ghost"
        //                             size="icon"
        //                             className="rounded-lg"
        //                             aria-label="Settings"
        //                         >
        //                             <Settings2 className="size-5" />
        //                         </Button>
        //                     </TooltipTrigger>
        //                     <TooltipContent side="right" sideOffset={5}>
        //                         Settings
        //                     </TooltipContent>
        //                 </Tooltip>
        //             </TooltipProvider>
        //         </nav>
        //         <nav className="mt-auto grid gap-1 p-2">
        //             <TooltipProvider>
        //                 <Tooltip>
        //                     <TooltipTrigger asChild>
        //                         <Button
        //                             variant="ghost"
        //                             size="icon"
        //                             className="mt-auto rounded-lg"
        //                             aria-label="Help"
        //                         >
        //                             <LifeBuoy className="size-5" />
        //                         </Button>
        //                     </TooltipTrigger>
        //                     <TooltipContent side="right" sideOffset={5}>
        //                         Help
        //                     </TooltipContent>
        //                 </Tooltip>
        //             </TooltipProvider>

        //             <TooltipProvider>
        //                 <Tooltip>
        //                     <TooltipTrigger asChild>
        //                         <Button
        //                             variant="ghost"
        //                             size="icon"
        //                             className="mt-auto rounded-lg"
        //                             aria-label="Account"
        //                         >
        //                             <SquareUser className="size-5" />
        //                         </Button>
        //                     </TooltipTrigger>
        //                     <TooltipContent side="right" sideOffset={5}>
        //                         Account
        //                     </TooltipContent>
        //                 </Tooltip>
        //             </TooltipProvider>
        //         </nav>
        //     </aside>
        //     <div className="flex flex-col">
        //         <header className="sticky top-0 z-10 flex h-[70px] items-center gap-1 border-b bg-background px-4">
        //             <h1 className="text-xl font-semibold">Playground</h1>
        //             {/* <Drawer>
        //                 <DrawerTrigger asChild>
        //                     <Button variant="ghost" size="icon" className="md:hidden">
        //                         <Settings className="size-4" />
        //                         <span className="sr-only">Settings</span>
        //                     </Button>
        //                 </DrawerTrigger>
        //                 <DrawerContent className="max-h-[80vh]">
        //                     <DrawerHeader>
        //                         <DrawerTitle>Configuration</DrawerTitle>
        //                         <DrawerDescription>
        //                             Configure the settings for the model and messages.
        //                         </DrawerDescription>
        //                     </DrawerHeader>
        //                     <form className="grid w-full items-start gap-6 overflow-auto p-4 pt-0">
        //                         <fieldset className="grid gap-6 rounded-lg border p-4">
        //                             <legend className="-ml-1 px-1 text-sm font-medium">
        //                                 Settings
        //                             </legend>
        //                             <div className="grid gap-3">
        //                                 <Label htmlFor="model">Model</Label>
        //                                 <Select>
        //                                     <SelectTrigger
        //                                         id="model"
        //                                         className="items-start [&_[data-description]]:hidden"
        //                                     >
        //                                         <SelectValue placeholder="Select a model" />
        //                                     </SelectTrigger>
        //                                     <SelectContent>
        //                                         <SelectItem value="genesis">
        //                                             <div className="flex items-start gap-3 text-muted-foreground">
        //                                                 <Rabbit className="size-5" />
        //                                                 <div className="grid gap-0.5">
        //                                                     <p>
        //                                                         Neural{' '}
        //                                                         <span className="font-medium text-foreground">
        //                                                             Genesis
        //                                                         </span>
        //                                                     </p>
        //                                                     <p className="text-xs" data-description>
        //                                                         Our fastest model for general use
        //                                                         cases.
        //                                                     </p>
        //                                                 </div>
        //                                             </div>
        //                                         </SelectItem>
        //                                         <SelectItem value="explorer">
        //                                             <div className="flex items-start gap-3 text-muted-foreground">
        //                                                 <Bird className="size-5" />
        //                                                 <div className="grid gap-0.5">
        //                                                     <p>
        //                                                         Neural{' '}
        //                                                         <span className="font-medium text-foreground">
        //                                                             Explorer
        //                                                         </span>
        //                                                     </p>
        //                                                     <p className="text-xs" data-description>
        //                                                         Performance and speed for
        //                                                         efficiency.
        //                                                     </p>
        //                                                 </div>
        //                                             </div>
        //                                         </SelectItem>
        //                                         <SelectItem value="quantum">
        //                                             <div className="flex items-start gap-3 text-muted-foreground">
        //                                                 <Turtle className="size-5" />
        //                                                 <div className="grid gap-0.5">
        //                                                     <p>
        //                                                         Neural{' '}
        //                                                         <span className="font-medium text-foreground">
        //                                                             Quantum
        //                                                         </span>
        //                                                     </p>
        //                                                     <p className="text-xs" data-description>
        //                                                         The most powerful model for complex
        //                                                         computations.
        //                                                     </p>
        //                                                 </div>
        //                                             </div>
        //                                         </SelectItem>
        //                                     </SelectContent>
        //                                 </Select>
        //                             </div>
        //                             <div className="grid gap-3">
        //                                 <Label htmlFor="temperature">Temperature</Label>
        //                                 <Input id="temperature" type="number" placeholder="0.4" />
        //                             </div>
        //                             <div className="grid gap-3">
        //                                 <Label htmlFor="top-p">Top P</Label>
        //                                 <Input id="top-p" type="number" placeholder="0.7" />
        //                             </div>
        //                             <div className="grid gap-3">
        //                                 <Label htmlFor="top-k">Top K</Label>
        //                                 <Input id="top-k" type="number" placeholder="0.0" />
        //                             </div>
        //                         </fieldset>
        //                         <fieldset className="grid gap-6 rounded-lg border p-4">
        //                             <legend className="-ml-1 px-1 text-sm font-medium">
        //                                 Messages
        //                             </legend>
        //                             <div className="grid gap-3">
        //                                 <Label htmlFor="role">Role</Label>
        //                                 <Select defaultValue="system">
        //                                     <SelectTrigger>
        //                                         <SelectValue placeholder="Select a role" />
        //                                     </SelectTrigger>
        //                                     <SelectContent>
        //                                         <SelectItem value="system">System</SelectItem>
        //                                         <SelectItem value="user">User</SelectItem>
        //                                         <SelectItem value="assistant">Assistant</SelectItem>
        //                                     </SelectContent>
        //                                 </Select>
        //                             </div>
        //                             <div className="grid gap-3">
        //                                 <Label htmlFor="content">Content</Label>
        //                                 <Textarea id="content" placeholder="You are a..." />
        //                             </div>
        //                         </fieldset>
        //                     </form>
        //                 </DrawerContent>
        //             </Drawer> */}
        //             {/* <Button variant="outline" size="sm" className="ml-auto gap-1.5 text-sm">
        //                 <Share className="size-3.5" />
        //                 Share
        //             </Button> */}
        //         </header>
        //         <main className="grid flex-1 gap-4 overflow-auto p-4 md:grid-cols-2 lg:grid-cols-3 bg-slate-100">
        //         </main>
        //     </div>
        // </div>
        <div className="h-screen w-full grid grid-cols-[60px,1fr]">
            <aside className="z-20 h-full flex flex-col justify-between pt-8 pb-8">
                <nav className="grid gap-4 justify-center items-start">
                    <Button
                        className="mx-2 h-full bg-none hover:bg-none ring-0 focus:ring-0"
                        size="icon"
                        aria-label="Home"
                    >
                        <img className="" src="pm-logo.svg" />
                    </Button>
                    <TooltipProvider delayDuration={50}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="mx-2 p-0 shadow-none  bg-auto bg-transparent hover:bg-emerald-100"
                                    aria-label="Playground"
                                >
                                    <img className="h-6 w-6" src="/icon-dashboard.svg" />
                                </Button>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                Playground
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                    <TooltipProvider delayDuration={50}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="mx-2 p-0 shadow-none bg-auto bg-transparent hover:bg-emerald-100"
                                    aria-label="Playground"
                                >
                                    <img className="h-6 w-6" src="/icon-charts.svg" />
                                </Button>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                Playground
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                    <TooltipProvider delayDuration={50}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="mx-2 p-0 shadow-none bg-auto bg-transparent  hover:bg-emerald-100"
                                    aria-label="Playground"
                                >
                                    <img className="h-6 w-6" src="/icon-connectors.svg" />
                                </Button>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                Playground
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                    <TooltipProvider delayDuration={50}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="mx-2 p-0 shadow-none bg-auto bg-transparent  hover:bg-emerald-100"
                                    aria-label="Playground"
                                >
                                    <img className="h-6 w-6" src="/icon-connections.svg" />
                                </Button>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                Connections
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                </nav>
                <nav className="mt-auto grid gap-4 justify-center items-start">
                    <TooltipProvider delayDuration={50}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="mx-2 p-0 shadow-none bg-auto bg-transparent  hover:bg-emerald-100"
                                    aria-label="Playground"
                                >
                                    <img className="h-6 w-6" src="/icon-setting.svg" />
                                </Button>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                Playground
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                    <TooltipProvider delayDuration={50}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="mx-2 p-0 shadow-none bg-auto bg-transparent  hover:bg-emerald-100"
                                    aria-label="Playground"
                                >
                                    <img className="h-6 w-6" src="/icon-documentation.svg" />
                                </Button>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                Connections
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                    <TooltipProvider delayDuration={50}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="mx-2 p-0 shadow-none bg-auto bg-transparent hover:bg-transparent"
                                    aria-label="Playground"
                                >
                                    <img className="h-8 w-8" src="/icon-avatar.svg" />
                                </Button>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                Logout
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                </nav>
            </aside>
            <div className="h-full flex flex-col flex-1">
                <div className="h-full my-8 mr-8 px-10 py-8 bg-slate-100">
                    <div className="flex gap-2">
                        <span className="text-2xl font-semibold">Playground</span>
                        <Button className="self-end" onClick={() => console.log('dashbaord')}>
                            <img className="" src="/icon-plus.svg" />
                            Add Dashboard
                        </Button>
                    </div>
                </div>
                <div className=""></div>
            </div>
        </div>
    );
}
