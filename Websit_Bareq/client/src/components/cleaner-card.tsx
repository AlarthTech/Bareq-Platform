import { Link } from "wouter";
import { type Cleaner } from "@shared/schema";
import { Star, MapPin, Clock, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";

export function CleanerCard({ cleaner }: { cleaner: Cleaner }) {
  // Format rating: 45 -> 4.5
  const displayRating = (cleaner.rating || 0) / 10;
  
  return (
    <div className="group bg-card rounded-2xl overflow-hidden border border-border/50 shadow-premium hover:shadow-premium-hover transition-all duration-300 hover:-translate-y-1 flex flex-col h-full">
      <div className="aspect-[4/3] w-full overflow-hidden relative bg-muted">
        {/* Unsplash placeholder for cleaner profile */}
        <img 
          src={cleaner.imageUrl || "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80"} 
          alt={cleaner.name}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
        />
        <div className="absolute top-4 right-4 bg-background/90 backdrop-blur-sm px-3 py-1 rounded-full text-sm font-bold flex items-center gap-1 shadow-sm">
          <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
          <span>{displayRating.toFixed(1)}</span>
        </div>
      </div>
      
      <div className="p-6 flex flex-col flex-1">
        <h3 className="font-display font-bold text-xl text-foreground mb-2">
          {cleaner.name}
        </h3>
        
        <p className="text-muted-foreground text-sm line-clamp-2 mb-4 flex-1">
          {cleaner.bio || "عاملة نظافة محترفة ذات خبرة عالية في تنظيف المنازل والمكاتب."}
        </p>
        
        <div className="flex flex-col gap-3 mb-6">
          <div className="flex items-center text-sm text-foreground font-medium">
            <div className="bg-primary/10 p-1.5 rounded-md me-3">
              <Clock className="w-4 h-4 text-primary" />
            </div>
            {cleaner.hourlyRate} ريال / ساعة
          </div>
        </div>
        
        <Link href={`/cleaners/${cleaner.id}`} className="mt-auto block">
          <Button className="w-full group/btn" variant="outline">
            عرض الملف الشخصي والحجز
            <ArrowLeft className="w-4 h-4 ms-2 group-hover/btn:-translate-x-1 transition-transform" />
          </Button>
        </Link>
      </div>
    </div>
  );
}
