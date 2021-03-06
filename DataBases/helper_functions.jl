
module cmap_helpers

using Pandas, PyCall
PyCmap = pyimport("pycmap")
#cmap = PyCmap.API(token="your-own-API-key")
cmap = PyCmap.API()

"""
    get(t::String,v::String)

Retrieve variable v from CMAP table t. Return along with
meta-data, position and time, in a Dict.
"""
function get(t::String,v::String)
    df=Pandas.DataFrame(cmap.get_dataset(t))
    me=Pandas.DataFrame(cmap.get_metadata(t,v))
    x=Dict("Variable" => v,"Unit" => deepcopy(values(me["Unit"])[1]),
    "Long_Name" => deepcopy(values(me["Long_Name"])[1]),
    "Data_Source" => deepcopy(values(me["Data_Source"])[1]),
    "lon" => deepcopy(values(df[:lon])),
    "lat" => deepcopy(values(df[:lat])),
    "time" => deepcopy(values(df[:time])),
    "val" => deepcopy(values(df[Symbol(v)])))
    return x
end

"""
    tables(ListName::String)

List of CMAP tables for subset `ListName`.
"""
    function tables(ListName::String)
        list0=[];
        if ListName=="G3"
            list0=["tblKM1906_Gradients3","tblKM1906_Gradients3_uway_optics","tblKM1906_Gradients3_uwayCTD"]
            #"tblKM1906_Gradients3_uw_tsg"
        elseif ListName=="G2"
            list0=["tblMGL1704_Gradients2_CTD","tblMGL1704_Gradients2_uway_optics"]
        elseif ListName=="G1"
            list0=["tblKOK1606_Gradients1_CTD","tblKOK1606_Gradients1_uway_optics"]
        elseif ListName=="MoreG1"
            list0=["tblKOK1606_Gradients1_Nutrients","tblKOK1606_Gradients1_Dissolved_Gasses",
            "tblKOK1606_Gradients1_TargetedMetabolites","tblKOK1606_Gradients1_Diazotroph"]
        elseif ListListNameId=="MoreG2"
            list0=["tblMGL1704_Gradients2_Nutrients","tblMGL1704_Gradients2_Diazotroph",
            "tblMGL1704_Gradients2_TargetedMetabolites","tblMGL1704_Gradients2_Trace_Metals"]
        end
        return list0
    end

end

module cbiomes_helpers

using MeshArrays, MITgcmTools
pth="../samples/gradients/"
!isdir("$pth") ? mkdir("$pth") : nothing

"""
    myinterp(pth::String,v::String,lon,lat)

Retrieve variable v from model output (`v*.".bin" binary file) and
interpolate using coefficients provided in `c*.".mat" file.
Return result as a Dict along with lon & lat.
"""
function myinterp(pth::String,v::String,lon,lat)

    gridpath="$pth"*"GRID_LLC90/"
    gitpath="https://github.com/gaelforget/GRID_LLC90"
    !isdir(gridpath) ? run(`git clone $gitpath $gridpath`) : nothing
    γ=GridSpec("LatLonCap",gridpath)
    Γ=GridLoad(γ)

    μ=γ.read(gridpath*"$v"*".bin",MeshArray(γ,Float32))
    msk=1.0 .+ 0.0 * mask(view(Γ["hFacC"],:,1),NaN,0.0)
    (f,i,j,w)=InterpolationFactors(Γ,vec(lon),vec(lat))
    μ=Interpolate(μ.*msk,f,i,j,w)

    return Dict("val" => μ, "lon" => lon, "lat" => lat, "Data_Source" => "ECCOv4r2 (Gael Forget)")
end

end
